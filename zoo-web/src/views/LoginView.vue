<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()
const username = ref('manager01')
const password = ref('Zoo@123456')
const loading = ref(false)

async function submit() {
  loading.value = true
  try {
    await auth.login(username.value, password.value)
    ElMessage.success('Đăng nhập thành công')
    router.push('/')
  } catch {
    /* interceptor đã báo */
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login">
    <div class="hero-panel">
      <p class="eyebrow">Hệ thống quản lý</p>
      <h1>Sở thú</h1>
      <p class="lead">Theo dõi động vật, chuồng trại, kho thức ăn và bán vé trên một bảng điều khiển gọn.</p>
    </div>
    <form class="card" @submit.prevent="submit">
      <h2>Đăng nhập</h2>
      <el-form label-position="top">
        <el-form-item label="Tên đăng nhập">
          <el-input v-model="username" autocomplete="username" />
        </el-form-item>
        <el-form-item label="Mật khẩu">
          <el-input v-model="password" type="password" show-password autocomplete="current-password" />
        </el-form-item>
        <el-button type="primary" native-type="submit" :loading="loading" style="width: 100%" @click="submit">
          Vào hệ thống
        </el-button>
      </el-form>
      <p class="hint">Demo: manager01 / vet01 / keeper01 / cashier01 — mật khẩu Zoo@123456</p>
    </form>
  </div>
</template>

<style scoped>
.login {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 1.1fr 0.9fr;
  gap: 2rem;
  align-items: center;
  padding: clamp(1.5rem, 5vw, 4rem);
  background:
    linear-gradient(120deg, rgba(27,67,50,0.88), rgba(20,40,29,0.55)),
    url('https://images.unsplash.com/photo-1564349683136-77e08dba1ef7?auto=format&fit=crop&w=1600&q=80')
      center/cover;
}
.hero-panel { color: #f8faf5; max-width: 34rem; }
.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.14em;
  font-size: 0.78rem;
  opacity: 0.85;
}
.hero-panel h1 {
  font-family: var(--font-display);
  font-size: clamp(3rem, 8vw, 5rem);
  margin: 0.2rem 0 0.8rem;
  line-height: 1;
}
.lead { font-size: 1.1rem; line-height: 1.55; opacity: 0.92; max-width: 28rem; }
.card {
  background: rgba(255,252,247,0.96);
  border-radius: 24px;
  padding: 1.75rem;
  box-shadow: var(--shadow);
  animation: rise 0.5s ease both;
}
.card h2 {
  margin: 0 0 1rem;
  font-family: var(--font-display);
}
.hint { margin-top: 1rem; color: var(--muted); font-size: 0.85rem; line-height: 1.4; }
@media (max-width: 860px) {
  .login { grid-template-columns: 1fr; }
  .hero-panel { order: -1; }
}
</style>
