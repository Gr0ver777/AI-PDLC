import { useCallback, useEffect, useMemo, useState } from 'react'
import type { FormEvent, ReactNode } from 'react'
import './App.css'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080/api'

type CaseModule = 'RESTRUCTURING' | 'BANKRUPTCY'
type CaseStatus = 'IN_REVIEW' | 'APPROVED' | 'NEEDS_MORE_INFO' | 'ESCALATED'
type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH'
type OperatorDecision = 'APPROVE' | 'REQUEST_INFO' | 'ESCALATE'

type SupportPlan = {
  nextContactDate: string
  relationshipManager: string
  contactChannel: string
  documentPackageStatus: string
  supportComment: string
}

type SlaPlan = {
  processingDeadline: string
  urgency: string
  slaComment: string
  slaStatus: string
}

type AssetCase = {
  id: number
  clientName: string
  clientId: string
  debtAmount: number
  overdueDays: number
  collateral: boolean
  module: CaseModule
  status: CaseStatus
  riskLevel: RiskLevel
  priority: 'NORMAL' | 'URGENT' | 'CRITICAL'
  recommendation: string
  createdAt: string
  supportPlan?: SupportPlan
  slaPlan?: SlaPlan
  newPaymentSchedule?: string
  restructuringTermMonths?: number
  newInterestRate?: number
  hardshipReason?: string
  bankruptcyStage?: string
  courtCaseNumber?: string
  debtorAssets?: string
  legalRisk?: string
  history: string[]
}

type View =
  | { name: 'dashboard' }
  | { name: 'restructuring' }
  | { name: 'bankruptcy' }
  | { name: 'case'; id: number }

const labels = {
  RESTRUCTURING: 'Реструктуризация',
  BANKRUPTCY: 'Банкротство',
  IN_REVIEW: 'На рассмотрении',
  APPROVED: 'Одобрено',
  NEEDS_MORE_INFO: 'Нужны документы',
  ESCALATED: 'Эскалировано',
  LOW: 'Низкий',
  MEDIUM: 'Средний',
  HIGH: 'Высокий',
}

function App() {
  const [view, setView] = useState<View>({ name: 'dashboard' })
  const [cases, setCases] = useState<AssetCase[]>([])
  const [selectedCase, setSelectedCase] = useState<AssetCase | null>(null)
  const [supportPlans, setSupportPlans] = useState<Record<number, SupportPlan>>({})
  const [slaPlans, setSlaPlans] = useState<Record<number, SlaPlan>>({})
  const [moduleFilter, setModuleFilter] = useState('')
  const [riskFilter, setRiskFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)

  const enrichCase = useCallback(
    (item: AssetCase): AssetCase => ({
      ...item,
      supportPlan: supportPlans[item.id] ?? item.supportPlan,
      slaPlan: slaPlans[item.id] ?? item.slaPlan,
    }),
    [slaPlans, supportPlans],
  )

  const loadCases = useCallback(async () => {
    const params = new URLSearchParams()
    if (moduleFilter) params.set('module', moduleFilter)
    if (riskFilter) params.set('riskLevel', riskFilter)
    if (statusFilter) params.set('status', statusFilter)
    try {
      const response = await fetch(`${API_URL}/cases?${params.toString()}`)
      if (response.ok) {
        const loadedCases: AssetCase[] = await response.json()
        setCases(loadedCases.map(enrichCase))
        return
      }
      setNotice('Не удалось загрузить список заявок. Проверьте backend.')
    } catch {
      setNotice('Backend недоступен. Проверьте, что Spring Boot запущен на порту 8080.')
    }
  }, [enrichCase, moduleFilter, riskFilter, statusFilter])

  const loadCase = useCallback(async (id: number) => {
    try {
      const response = await fetch(`${API_URL}/cases/${id}`)
      if (response.ok) {
        const loadedCase: AssetCase = await response.json()
        setSelectedCase(enrichCase(loadedCase))
        return
      }
      setNotice(`Не удалось загрузить заявку #${id}.`)
    } catch {
      setNotice('Backend недоступен. Проверьте, что Spring Boot запущен на порту 8080.')
    }
  }, [enrichCase])

  useEffect(() => {
    void loadCases()
  }, [loadCases])

  useEffect(() => {
    if (view.name === 'case') {
      void loadCase(view.id)
    }
  }, [loadCase, slaPlans, supportPlans, view])

  const stats = useMemo(
    () => ({
      total: cases.length,
      high: cases.filter((item) => item.riskLevel === 'HIGH').length,
      escalated: cases.filter((item) => item.status === 'ESCALATED').length,
    }),
    [cases],
  )

  async function submitCase(endpoint: string, payload: Record<string, unknown>, supportPlan?: SupportPlan, slaPlan?: SlaPlan) {
    setLoading(true)
    setNotice('')
    try {
      const response = await fetch(`${API_URL}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
      if (!response.ok) {
        setNotice('Не удалось создать заявку. Проверьте обязательные поля.')
        return
      }
      const created: AssetCase = await response.json()
      if (supportPlan) {
        setSupportPlans((current) => ({ ...current, [created.id]: supportPlan }))
        created.supportPlan = supportPlan
      }
      if (slaPlan) {
        setSlaPlans((current) => ({ ...current, [created.id]: slaPlan }))
        created.slaPlan = slaPlan
      }
      setNotice(`Заявка #${created.id} создана, риск: ${labels[created.riskLevel]}`)
      await loadCases()
      setSelectedCase(created)
      setView({ name: 'case', id: created.id })
    } catch {
      setNotice('Backend недоступен или вернул сетевую ошибку. Проверьте Spring Boot и PostgreSQL.')
    } finally {
      setLoading(false)
    }
  }

  async function applyDecision(decision: OperatorDecision) {
    if (!selectedCase) return
    const response = await fetch(`${API_URL}/cases/${selectedCase.id}/decision`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ decision, comment: 'Решение принято в рабочем месте MVP' }),
    })
    if (response.ok) {
      const updated: AssetCase = await response.json()
      setSelectedCase(enrichCase(updated))
      setNotice('Решение оператора сохранено')
      await loadCases()
    }
  }

  return (
    <main>
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-mark">AI</span>
          <div>
            <strong>AI-PDLC</strong>
            <span>Проблемные активы</span>
          </div>
        </div>
        <button className={view.name === 'dashboard' ? 'active' : ''} onClick={() => setView({ name: 'dashboard' })}>Обзор</button>
        <button className={view.name === 'restructuring' ? 'active' : ''} onClick={() => setView({ name: 'restructuring' })}>Реструктуризация</button>
        <button className={view.name === 'bankruptcy' ? 'active' : ''} onClick={() => setView({ name: 'bankruptcy' })}>Банкротство</button>
      </aside>

      <section className="workspace">
        {notice && <div className="notice">{notice}</div>}
        {view.name === 'dashboard' && (
          <Dashboard
            cases={cases}
            stats={stats}
            moduleFilter={moduleFilter}
            riskFilter={riskFilter}
            statusFilter={statusFilter}
            onModuleFilter={setModuleFilter}
            onRiskFilter={setRiskFilter}
            onStatusFilter={setStatusFilter}
            onOpen={(id) => setView({ name: 'case', id })}
          />
        )}
        {view.name === 'restructuring' && <RestructuringForm loading={loading} onSubmit={submitCase} />}
        {view.name === 'bankruptcy' && <BankruptcyForm loading={loading} onSubmit={submitCase} />}
        {view.name === 'case' && selectedCase && <CaseDetails item={selectedCase} onDecision={applyDecision} />}
      </section>
    </main>
  )
}

function Dashboard({
  cases,
  stats,
  moduleFilter,
  riskFilter,
  statusFilter,
  onModuleFilter,
  onRiskFilter,
  onStatusFilter,
  onOpen,
}: {
  cases: AssetCase[]
  stats: { total: number; high: number; escalated: number }
  moduleFilter: string
  riskFilter: string
  statusFilter: string
  onModuleFilter: (value: string) => void
  onRiskFilter: (value: string) => void
  onStatusFilter: (value: string) => void
  onOpen: (id: number) => void
}) {
  return (
    <>
      <header className="page-header">
        <div>
          <h1>Рабочая панель отдела</h1>
          <p>Очередь заявок, AI-оценка риска и быстрые решения оператора.</p>
        </div>
      </header>
      <div className="metrics">
        <Metric title="Всего заявок" value={stats.total} />
        <Metric title="Высокий риск" value={stats.high} />
        <Metric title="Эскалации" value={stats.escalated} />
      </div>
      <div className="filters">
        <Select value={moduleFilter} onChange={onModuleFilter} label="Модуль" options={[['', 'Все'], ['RESTRUCTURING', 'Реструктуризация'], ['BANKRUPTCY', 'Банкротство']]} />
        <Select value={riskFilter} onChange={onRiskFilter} label="Риск" options={[['', 'Все'], ['LOW', 'Низкий'], ['MEDIUM', 'Средний'], ['HIGH', 'Высокий']]} />
        <Select value={statusFilter} onChange={onStatusFilter} label="Статус" options={[['', 'Все'], ['IN_REVIEW', 'На рассмотрении'], ['APPROVED', 'Одобрено'], ['NEEDS_MORE_INFO', 'Нужны документы'], ['ESCALATED', 'Эскалировано']]} />
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Клиент</th>
              <th>Модуль</th>
              <th>Долг</th>
              <th>Риск</th>
              <th>Статус</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {cases.map((item) => (
              <tr key={item.id}>
                <td>#{item.id}</td>
                <td>{item.clientName}</td>
                <td>{labels[item.module]}</td>
                <td>{formatMoney(item.debtAmount)}</td>
                <td><span className={`pill ${item.riskLevel.toLowerCase()}`}>{labels[item.riskLevel]}</span></td>
                <td>{labels[item.status]}</td>
                <td><button className="ghost" onClick={() => onOpen(item.id)}>Открыть</button></td>
              </tr>
            ))}
            {cases.length === 0 && (
              <tr>
                <td colSpan={7} className="empty">Заявок пока нет</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </>
  )
}

function RestructuringForm({ loading, onSubmit }: { loading: boolean; onSubmit: (endpoint: string, payload: Record<string, unknown>, supportPlan?: SupportPlan, slaPlan?: SlaPlan) => void }) {
  return (
    <CaseForm title="Новая реструктуризация" loading={loading} onSubmit={(base, form) => onSubmit('restructuring-cases', {
      ...base,
      newPaymentSchedule: value(form, 'newPaymentSchedule'),
      restructuringTermMonths: numberValue(form, 'restructuringTermMonths'),
      newInterestRate: numberValue(form, 'newInterestRate'),
      hardshipReason: value(form, 'hardshipReason'),
    }, supportPlanFrom(form), slaPlanFrom(form))}>
      <Input name="newPaymentSchedule" label="Новый график" required defaultValue="Ежемесячно равными платежами" />
      <Input name="restructuringTermMonths" label="Срок, мес." type="number" required defaultValue="18" />
      <Input name="newInterestRate" label="Новая ставка, %" type="number" step="0.1" required defaultValue="11.5" />
      <TextArea name="hardshipReason" label="Причина ухудшения платежеспособности" required defaultValue="Снижение выручки и временный кассовый разрыв" />
      <SupportPlanFields />
      <SlaPlanFields />
    </CaseForm>
  )
}

function BankruptcyForm({ loading, onSubmit }: { loading: boolean; onSubmit: (endpoint: string, payload: Record<string, unknown>) => void }) {
  return (
    <CaseForm title="Новая заявка на банкротство" loading={loading} onSubmit={(base, form) => onSubmit('bankruptcy-cases', {
      ...base,
      bankruptcyStage: value(form, 'bankruptcyStage'),
      courtCaseNumber: value(form, 'courtCaseNumber'),
      debtorAssets: value(form, 'debtorAssets'),
      legalRisk: value(form, 'legalRisk'),
    })}>
      <Input name="bankruptcyStage" label="Стадия процесса" required defaultValue="Наблюдение" />
      <Input name="courtCaseNumber" label="Судебное дело" required defaultValue="А40-10001/2026" />
      <TextArea name="debtorAssets" label="Активы должника" required defaultValue="Складской комплекс, дебиторская задолженность, оборудование" />
      <TextArea name="legalRisk" label="Юридический риск" required defaultValue="Риск оспаривания сделок и недостаточности конкурсной массы" />
    </CaseForm>
  )
}

function CaseForm({ title, loading, children, onSubmit }: { title: string; loading: boolean; children: ReactNode; onSubmit: (base: Record<string, unknown>, form: HTMLFormElement) => void }) {
  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = event.currentTarget
    onSubmit({
      clientName: value(form, 'clientName'),
      clientId: value(form, 'clientId'),
      debtAmount: numberValue(form, 'debtAmount'),
      overdueDays: numberValue(form, 'overdueDays'),
      collateral: (form.elements.namedItem('collateral') as HTMLInputElement).checked,
    }, form)
  }

  return (
    <form className="form-panel" onSubmit={handleSubmit}>
      <h1>{title}</h1>
      <div className="form-grid">
        <Input name="clientName" label="Клиент" required defaultValue="ООО Север" />
        <Input name="clientId" label="ИНН / ID" required defaultValue="7701000011" />
        <Input name="debtAmount" label="Сумма долга" type="number" required defaultValue="2500000" />
        <Input name="overdueDays" label="Просрочка, дней" type="number" required defaultValue="75" />
        <label className="checkbox"><input name="collateral" type="checkbox" defaultChecked /> Есть обеспечение</label>
        {children}
      </div>
      <button className="primary" disabled={loading}>{loading ? 'Создание...' : 'Создать заявку'}</button>
    </form>
  )
}

function SupportPlanFields() {
  return (
    <fieldset className="support-plan">
      <legend>План сопровождения клиента</legend>
      <Input name="nextContactDate" label="Дата следующего контакта" type="date" required defaultValue="2026-06-01" />
      <Input name="relationshipManager" label="Ответственный менеджер" required defaultValue="Иван Петров" />
      <SelectInput name="contactChannel" label="Канал связи" required defaultValue="Телефон" options={['Телефон', 'Email', 'Встреча', 'Мессенджер']} />
      <SelectInput name="documentPackageStatus" label="Статус пакета документов" required defaultValue="Запрошен" options={['Не запрошен', 'Запрошен', 'Получен частично', 'Получен полностью']} />
      <TextArea name="supportComment" label="Комментарий по сопровождению" defaultValue="Согласовать дату звонка и проверить комплектность документов" />
    </fieldset>
  )
}

function SlaPlanFields() {
  const defaultDeadline = '2026-05-26'
  const [deadline, setDeadline] = useState(defaultDeadline)

  return (
    <fieldset className="support-plan sla-plan">
      <legend>SLA обработки</legend>
      <Input
        name="processingDeadline"
        label="Дедлайн обработки"
        type="date"
        required
        defaultValue={defaultDeadline}
        onChange={(event) => setDeadline(event.target.value)}
      />
      <SelectInput name="urgency" label="Срочность" required defaultValue="Повышенная" options={['Стандартная', 'Повышенная', 'Критическая']} />
      <TextArea name="slaComment" label="Комментарий по SLA" defaultValue="Проконтролировать контакт до дедлайна" />
      <div className="sla-status" aria-live="polite">
        <span>SLA-статус</span>
        <strong>{calculateSlaStatus(deadline)}</strong>
      </div>
    </fieldset>
  )
}

function CaseDetails({ item, onDecision }: { item: AssetCase; onDecision: (decision: OperatorDecision) => void }) {
  return (
    <article className="details">
      <header className="page-header">
        <div>
          <h1>Заявка #{item.id}: {item.clientName}</h1>
          <p>{labels[item.module]} · {labels[item.status]}</p>
        </div>
        <span className={`pill ${item.riskLevel.toLowerCase()}`}>{labels[item.riskLevel]} риск</span>
      </header>
      <section className="recommendation">
        <h2>AI-рекомендация</h2>
        <p>{item.recommendation}</p>
      </section>
      <div className="details-grid">
        <Info label="ИНН / ID" value={item.clientId} />
        <Info label="Сумма долга" value={formatMoney(item.debtAmount)} />
        <Info label="Просрочка" value={`${item.overdueDays} дней`} />
        <Info label="Обеспечение" value={item.collateral ? 'Да' : 'Нет'} />
        {item.module === 'RESTRUCTURING' ? (
          <>
            <Info label="Новый график" value={item.newPaymentSchedule} />
            <Info label="Срок" value={`${item.restructuringTermMonths} мес.`} />
            <Info label="Ставка" value={`${item.newInterestRate}%`} />
            <Info label="Причина" value={item.hardshipReason} />
          </>
        ) : (
          <>
            <Info label="Стадия" value={item.bankruptcyStage} />
            <Info label="Дело" value={item.courtCaseNumber} />
            <Info label="Активы" value={item.debtorAssets} />
            <Info label="Юридический риск" value={item.legalRisk} />
          </>
        )}
      </div>
      {item.supportPlan && (
        <section className="recommendation support-summary">
          <h2>План сопровождения клиента</h2>
          <div className="details-grid compact">
            <Info label="Следующий контакт" value={formatDate(item.supportPlan.nextContactDate)} />
            <Info label="Ответственный" value={item.supportPlan.relationshipManager} />
            <Info label="Канал связи" value={item.supportPlan.contactChannel} />
            <Info label="Документы" value={item.supportPlan.documentPackageStatus} />
            <Info label="Комментарий" value={item.supportPlan.supportComment || 'Не указан'} />
          </div>
        </section>
      )}
      {item.slaPlan && (
        <section className="recommendation support-summary">
          <h2>SLA обработки</h2>
          <div className="details-grid compact">
            <Info label="Дедлайн" value={formatDate(item.slaPlan.processingDeadline)} />
            <Info label="Срочность" value={item.slaPlan.urgency} />
            <Info label="SLA-статус" value={item.slaPlan.slaStatus} />
            <Info label="Комментарий" value={item.slaPlan.slaComment || 'Не указан'} />
          </div>
        </section>
      )}
      <div className="actions">
        <button className="primary" onClick={() => onDecision('APPROVE')}>Принять</button>
        <button onClick={() => onDecision('REQUEST_INFO')}>Запросить документы</button>
        <button onClick={() => onDecision('ESCALATE')}>Эскалировать</button>
      </div>
      <section className="history">
        <h2>История</h2>
        {item.history.map((event) => <p key={event}>{event}</p>)}
      </section>
    </article>
  )
}

function Metric({ title, value }: { title: string; value: number }) {
  return <div className="metric"><span>{title}</span><strong>{value}</strong></div>
}

function Select({ label, value, options, onChange }: { label: string; value: string; options: string[][]; onChange: (value: string) => void }) {
  return (
    <label>
      {label}
      <select value={value} onChange={(event) => onChange(event.target.value)}>
        {options.map(([optionValue, text]) => <option key={optionValue} value={optionValue}>{text}</option>)}
      </select>
    </label>
  )
}

function SelectInput(props: React.SelectHTMLAttributes<HTMLSelectElement> & { label: string; options: string[] }) {
  const { label, options, ...selectProps } = props
  return (
    <label>
      {label}
      <select {...selectProps}>
        {options.map((option) => <option key={option} value={option}>{option}</option>)}
      </select>
    </label>
  )
}

function Input(props: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  const { label, ...inputProps } = props
  return <label>{label}<input {...inputProps} /></label>
}

function TextArea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement> & { label: string }) {
  const { label, ...inputProps } = props
  return <label className="wide">{label}<textarea {...inputProps} /></label>
}

function Info({ label, value }: { label: string; value?: string | number }) {
  return <div className="info"><span>{label}</span><strong>{value ?? 'Не указано'}</strong></div>
}

function value(form: HTMLFormElement, name: string) {
  return (form.elements.namedItem(name) as HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement).value
}

function numberValue(form: HTMLFormElement, name: string) {
  return Number(value(form, name))
}

function supportPlanFrom(form: HTMLFormElement): SupportPlan {
  return {
    nextContactDate: value(form, 'nextContactDate'),
    relationshipManager: value(form, 'relationshipManager'),
    contactChannel: value(form, 'contactChannel'),
    documentPackageStatus: value(form, 'documentPackageStatus'),
    supportComment: value(form, 'supportComment'),
  }
}

function slaPlanFrom(form: HTMLFormElement): SlaPlan {
  const processingDeadline = value(form, 'processingDeadline')
  return {
    processingDeadline,
    urgency: value(form, 'urgency'),
    slaComment: value(form, 'slaComment'),
    slaStatus: calculateSlaStatus(processingDeadline),
  }
}

function formatMoney(value: number) {
  return new Intl.NumberFormat('ru-RU', { style: 'currency', currency: 'RUB', maximumFractionDigits: 0 }).format(value)
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat('ru-RU').format(new Date(value))
}

function calculateSlaStatus(deadline: string) {
  if (!deadline) {
    return 'Не задан'
  }
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const deadlineDate = new Date(deadline)
  deadlineDate.setHours(0, 0, 0, 0)
  const diffDays = Math.ceil((deadlineDate.getTime() - today.getTime()) / 86_400_000)
  if (diffDays <= 0) {
    return 'Критично'
  }
  if (diffDays <= 3) {
    return 'Под контролем'
  }
  return 'В срок'
}

export default App
