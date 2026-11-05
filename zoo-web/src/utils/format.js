import dayjs from 'dayjs'

export function formatDate(v) {
  if (!v) return '—'
  const d = dayjs(v)
  return d.isValid() ? d.format('DD/MM/YYYY') : String(v)
}

export function formatDateTime(v) {
  if (!v) return '—'
  const d = dayjs(v)
  return d.isValid() ? d.format('DD/MM/YYYY HH:mm') : String(v)
}

export function formatMoney(v) {
  const n = Number(v || 0)
  return `${n.toLocaleString('vi-VN')} ₫`
}

export function toInputDate(v) {
  if (!v) return ''
  const d = dayjs(v)
  return d.isValid() ? d.format('YYYY-MM-DD') : ''
}
