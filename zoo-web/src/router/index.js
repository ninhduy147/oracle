import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/LoginView.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    component: () => import('../layouts/AppLayout.vue'),
    children: [
      { path: '', name: 'dashboard', component: () => import('../views/DashboardView.vue') },
      { path: 'animals', name: 'animals', component: () => import('../views/AnimalsView.vue') },
      { path: 'zones', name: 'zones', component: () => import('../views/ZonesView.vue'), meta: { roles: ['MANAGER'] } },
      { path: 'enclosures', name: 'enclosures', component: () => import('../views/EnclosuresView.vue') },
      { path: 'species', name: 'species', component: () => import('../views/SpeciesView.vue') },
      { path: 'staff', name: 'staff', component: () => import('../views/StaffView.vue'), meta: { roles: ['MANAGER', 'VET', 'KEEPER'] } },
      { path: 'food', name: 'food', component: () => import('../views/FoodView.vue') },
      { path: 'medical', name: 'medical', component: () => import('../views/MedicalView.vue'), meta: { roles: ['MANAGER', 'VET'] } },
      { path: 'tickets', name: 'tickets', component: () => import('../views/TicketsView.vue'), meta: { roles: ['MANAGER', 'CASHIER'] } },
      { path: 'revenue', name: 'revenue', component: () => import('../views/RevenueView.vue'), meta: { roles: ['MANAGER', 'CASHIER'] } },
      { path: 'audit', name: 'audit', component: () => import('../views/AuditView.vue'), meta: { roles: ['MANAGER'] } },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isLoggedIn) return { name: 'login' }
  if (to.name === 'login' && auth.isLoggedIn) return { name: 'dashboard' }
  const roles = to.meta.roles
  if (roles && !roles.includes(auth.role)) return { name: 'dashboard' }
  return true
})

export default router
