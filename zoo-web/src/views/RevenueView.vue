<script setup>
import { onMounted, ref, computed } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import api from '../api/client'
import { formatDate, formatMoney } from '../utils/format'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler)

const dateFrom = ref('')
const dateTo = ref('')
const report = ref(null)

onMounted(async () => {
  await load()
})

async function load() {
  const params = {}
  if (dateFrom.value) params.date_from = dateFrom.value
  if (dateTo.value) params.date_to = dateTo.value
  const { data } = await api.get('/api/reports/revenue', { params })
  report.value = data
  dateFrom.value = data.date_from
  dateTo.value = data.date_to
}

const chart = computed(() => ({
  labels: (report.value?.days || []).map((d) => formatDate(d.sale_date)),
  datasets: [
    {
      label: 'Doanh thu',
      data: (report.value?.days || []).map((d) => d.revenue),
      borderColor: '#bc6c25',
      backgroundColor: 'rgba(188,108,37,0.15)',
      fill: true,
      tension: 0.3,
    },
  ],
}))
</script>

<template>
  <section class="page">
    <header class="page-head">
      <div>
        <h1>Báo cáo doanh thu</h1>
        <p class="muted">Theo khoảng ngày (fn_revenue)</p>
      </div>
      <div class="actions">
        <el-date-picker v-model="dateFrom" type="date" value-format="YYYY-MM-DD" format="DD/MM/YYYY" placeholder="Từ" />
        <el-date-picker v-model="dateTo" type="date" value-format="YYYY-MM-DD" format="DD/MM/YYYY" placeholder="Đến" />
        <el-button type="primary" @click="load">Xem</el-button>
      </div>
    </header>

    <div class="stat-card" v-if="report" style="margin-bottom:1rem;max-width:320px">
      <div class="label">Tổng doanh thu</div>
      <div class="value" style="font-size:1.6rem">{{ formatMoney(report.total) }}</div>
    </div>

    <div class="panel" v-if="report">
      <Line :data="chart" :options="{ responsive: true, plugins: { legend: { display: false } } }" />
      <el-table :data="report.days" style="margin-top:1rem" size="small">
        <el-table-column label="Ngày">
          <template #default="{ row }">{{ formatDate(row.sale_date) }}</template>
        </el-table-column>
        <el-table-column prop="invoice_count" label="Số HĐ" width="100" />
        <el-table-column label="Doanh thu">
          <template #default="{ row }">{{ formatMoney(row.revenue) }}</template>
        </el-table-column>
      </el-table>
    </div>
  </section>
</template>

<style scoped>
.page-head {
  display: flex; flex-wrap: wrap; justify-content: space-between; gap: 1rem; align-items: end;
  margin-bottom: 1rem;
}
.page-head h1 { margin: 0; font-family: var(--font-display); }
.muted { margin: 0.25rem 0 0; color: var(--muted); }
.actions { display: flex; flex-wrap: wrap; gap: 0.5rem; }
</style>
