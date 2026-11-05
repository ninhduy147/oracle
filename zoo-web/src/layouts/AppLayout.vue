<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { labelOf } from '../labels'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const menus = computed(() => {
  const all = [
    { to: '/', label: 'Tổng quan', roles: null },
    { to: '/animals', label: 'Động vật', roles: null },
    { to: '/enclosures', label: 'Chuồng', roles: null },
    { to: '/species', label: 'Loài', roles: null },
    { to: '/zones', label: 'Khu vực', roles: ['MANAGER'] },
    { to: '/staff', label: 'Nhân viên', roles: ['MANAGER', 'VET', 'KEEPER'] },
    { to: '/food', label: 'Thức ăn & kho', roles: null },
    { to: '/medical', label: 'Khám bệnh', roles: ['MANAGER', 'VET'] },
    { to: '/tickets', label: 'Bán vé', roles: ['MANAGER', 'CASHIER'] },
    { to: '/revenue', label: 'Doanh thu', roles: ['MANAGER', 'CASHIER'] },
    { to: '/audit', label: 'Nhật ký', roles: ['MANAGER'] },
  ]
  return all.filter((m) => !m.roles || m.roles.includes(auth.role))
})

function logout() {
  auth.logout()
  router.push('/login')
}
</script>

<template>
  <div class="shell">
    <aside class="side no-print">
      <div class="brand">
        <span class="mark">Z</span>
        <div>
          <strong>Sở thú</strong>
          <small>Quản lý vận hành</small>
        </div>
      </div>
      <nav>
        <router-link
          v-for="m in menus"
          :key="m.to"
          :to="m.to"
          class="nav-item"
          :class="{ active: route.path === m.to }"
        >
          {{ m.label }}
        </router-link>
      </nav>
      <div class="side-foot">
        <div class="who">
          <strong>{{ auth.fullName || auth.username }}</strong>
          <small>{{ labelOf('role', auth.role) }}</small>
        </div>
        <el-button text @click="logout">Đăng xuất</el-button>
      </div>
    </aside>
    <main class="main">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.shell {
  display: grid;
  grid-template-columns: 260px 1fr;
  min-height: 100vh;
}
.side {
  position: sticky;
  top: 0;
  height: 100vh;
  padding: 1.25rem 1rem;
  background: linear-gradient(180deg, var(--leaf-deep), #081c15 120%);
  color: #f1faee;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}
.brand {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  padding: 0.25rem 0.5rem;
}
.mark {
  width: 42px; height: 42px;
  border-radius: 14px;
  display: grid; place-items: center;
  background: #95d5b2;
  color: var(--leaf-deep);
  font-family: var(--font-display);
  font-weight: 700;
  font-size: 1.3rem;
}
.brand strong { display: block; font-family: var(--font-display); font-size: 1.2rem; }
.brand small, .who small { color: #b7cfc0; }
nav { display: flex; flex-direction: column; gap: 0.25rem; flex: 1; overflow: auto; }
.nav-item {
  padding: 0.7rem 0.9rem;
  border-radius: 12px;
  color: #d8f3dc;
  transition: background 0.2s ease, transform 0.2s ease;
}
.nav-item:hover { background: rgba(255,255,255,0.08); transform: translateX(2px); }
.nav-item.active { background: rgba(149, 213, 178, 0.22); color: #fff; font-weight: 600; }
.side-foot {
  border-top: 1px solid rgba(255,255,255,0.12);
  padding-top: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
}
.who strong { display: block; font-size: 0.95rem; }
.main {
  padding: 1.5rem clamp(1rem, 3vw, 2rem) 2.5rem;
  min-width: 0;
}
@media (max-width: 860px) {
  .shell { grid-template-columns: 1fr; }
  .side {
    position: relative;
    height: auto;
    border-radius: 0 0 18px 18px;
  }
  nav {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
