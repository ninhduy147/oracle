import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api/client'

const STORAGE_KEY = 'zoo_auth'

export const useAuthStore = defineStore('auth', () => {
  const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null')
  const token = ref(saved?.token || '')
  const username = ref(saved?.username || '')
  const role = ref(saved?.role || '')
  const employeeId = ref(saved?.employee_id || null)
  const fullName = ref(saved?.full_name || '')

  const isLoggedIn = computed(() => !!token.value)

  function persist() {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        token: token.value,
        username: username.value,
        role: role.value,
        employee_id: employeeId.value,
        full_name: fullName.value,
      }),
    )
  }

  async function login(user, pass) {
    const { data } = await api.post('/api/auth/login', {
      username: user,
      password: pass,
    })
    token.value = data.access_token
    username.value = data.username
    role.value = data.role
    employeeId.value = data.employee_id
    fullName.value = data.full_name
    persist()
  }

  function logout() {
    token.value = ''
    username.value = ''
    role.value = ''
    employeeId.value = null
    fullName.value = ''
    localStorage.removeItem(STORAGE_KEY)
  }

  function can(...roles) {
    return roles.includes(role.value)
  }

  return {
    token,
    username,
    role,
    employeeId,
    fullName,
    isLoggedIn,
    login,
    logout,
    can,
  }
})
