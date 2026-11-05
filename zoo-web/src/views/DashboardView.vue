<script setup>
import { onMounted, ref, computed } from 'vue'
import { Line, Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  ArcElement,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import api from '../api/client'
import { formatMoney, formatDate } from '../utils/format'
import { labelOf } from '../labels'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, ArcElement, Tooltip, Legend, Filler)

const data = ref(null)
const loading = ref(true)

onMounted(async () => {
  try {
    const res = await api.get('/api/reports/overview')
    data.value = res.data
  } finally {
    loading.value = false
  }
})

const revenueChart = computed(() => {
  const rows = data.value?.revenue_7d || []
  return {
    labels: rows.map((r) => formatDate(r.sale_date)),
    datasets: [
      {
        label: 'Doanh thu',
        data: rows.map((r) => r.revenue),
        borderColor: '#2d6a4f',
        backgroundColor: 'rgba(45,106,79,0.15)',
        fill: true,
        tension: 0.35,
      },
    ],
  }
})

const classChart = computed(() => {
  const rows = data.value?.animals_by_class || []
  return {
    labels: rows.map((r) => labelOf('class_group', r.class_group)),
    datasets: [
      {
        data: rows.map((r) => r.count),
        backgroundColor: ['#1b4332', '#2d6a4f', '#40916c', '#74c69d', '#bc6c25'],
      },
    ],
  }
})
</script>

<template>
  <section class="page" v-loading="loading">
    <header class="page-head">
      <div>
        <h1>Tổng quan</h1>
        <p class="muted">Số liệu vận hành hôm nay</p>
      </div>
    </header>

    <div class="stat-grid" v-if="data">
      <div class="stat-card"><div class="label">Động vật</div><div class="value">{{ data.cards.animals }}</div></div>
      <div class="stat-card"><div class="label">Nhân viên</div><div class="value">{{ data.cards.employees }}</div></div>
      <div class="stat-card"><div class="label">Kho thấp</div><div class="value">{{ data.cards.low_stock }}</div></div>
      <div class="stat-card"><div class="label">Tái khám tới</div><div class="value">{{ data.cards.followups }}</div></div>
    </div>

    <div class="charts" v-if="data">
      <div class="panel">
        <h2>Doanh thu 7 ngày</h2>
        <Line :data="revenueChart" :options="{ responsive: true, plugins: { legend: { display: false } } }" />
      </div>
      <div class="panel">
        <h2>Động vật theo nhóm</h2>
        <Doughnut :data="classChart" :options="{ responsive: true }" />
      </div>
    </div>

    <div class="lists" v-if="data">
      <div class="panel">
        <h2>Cảnh báo kho thấp</h2>
        <el-table :data="data.low_stock_foods" size="small" empty-text="Không có cảnh báo">
          <el-table-column prop="name" label="Thức ăn" />
          <el-table-column prop="stock_qty" label="Tồn" width="90" />
          <el-table-column prop="min_stock" label="Tối thiểu" width="100" />
          <el-table-column prop="shortage" label="Thiếu" width="90" />
        </el-table>
      </div>
      <div class="panel">
        <h2>Tái khám trong 7 ngày</h2>
        <el-table :data="data.upcoming_followups" size="small" empty-text="Không có lịch">
          <el-table-column prop="animal_name" label="Động vật" />
          <el-table-column prop="vet_name" label="Bác sĩ" />
          <el-table-column label="Ngày tái khám" width="130">
            <template #default="{ row }">{{ formatDate(row.follow_up_date) }}</template>
          </el-table-column>
        </el-table>
      </div>
    </div>
  </section>
</template>

<style scoped>
.page-head { margin-bottom: 1.25rem; }
.page-head h1 { margin: 0; font-family: var(--font-display); font-size: 1.9rem; }
.muted { margin: 0.25rem 0 0; color: var(--muted); }
.charts, .lists {
  display: grid;
  grid-template-columns: 1.3fr 1fr;
  gap: 1rem;
  margin-top: 1.25rem;
}
@media (max-width: 960px) {
  .charts, .lists { grid-template-columns: 1fr; }
}
</style>
