import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  timeout: 30000,
})

api.interceptors.request.use((config) => {
  const auth = useAuthStore()
  if (auth.token) {
    config.headers.Authorization = `Bearer ${auth.token}`
  }
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    const detail = err.response?.data?.detail
    const msg = typeof detail === 'string' ? detail : err.message || 'Lỗi mạng'
    if (err.response?.status === 401) {
      const auth = useAuthStore()
      auth.logout()
      if (!location.pathname.includes('/login')) {
        location.href = '/login'
      }
    } else {
      ElMessage.error(msg)
    }
    return Promise.reject(err)
  },
)

export default api

export const crudApi = {
  list: (table, params) => api.get(`/api/crud/${table}`, { params }).then((r) => r.data),
  get: (table, id) => api.get(`/api/crud/${table}/${id}`).then((r) => r.data),
  create: (table, body) => api.post(`/api/crud/${table}`, body).then((r) => r.data),
  update: (table, id, body) => api.put(`/api/crud/${table}/${id}`, body).then((r) => r.data),
  remove: (table, id) => api.delete(`/api/crud/${table}/${id}`).then((r) => r.data),
}
