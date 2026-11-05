<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import api, { crudApi } from '../api/client'
import { formatMoney } from '../utils/format'
import { labelOf } from '../labels'

const types = ref([])
const customers = ref([])
const form = reactive({
  customer_id: null,
  payment_method: 'CASH',
  items: [{ ticket_type_id: 1, quantity: 1 }],
})
const lastInvoice = ref(null)

onMounted(async () => {
  const [t, c] = await Promise.all([
    api.get('/api/tickets/types'),
    crudApi.list('customers', { page_size: 100 }),
  ])
  types.value = t.data
  customers.value = c.items
  if (types.value[0]) form.items[0].ticket_type_id = types.value[0].id
})

function addLine() {
  form.items.push({ ticket_type_id: types.value[0]?.id, quantity: 1 })
}

const previewTotal = () =>
  form.items.reduce((sum, it) => {
    const price = types.value.find((t) => t.id === it.ticket_type_id)?.price || 0
    return sum + price * (it.quantity || 0)
  }, 0)

async function checkout() {
  const { data } = await api.post('/api/tickets/sale', { ...form })
  lastInvoice.value = data
  ElMessage.success(`Đã lập hóa đơn #${data.invoice_id}`)
}

function printInvoice() {
  window.print()
}
</script>

<template>
  <section class="page">
    <header class="page-head no-print">
      <div>
        <h1>Bán vé</h1>
        <p class="muted">Lập hóa đơn qua procedure Oracle</p>
      </div>
    </header>

    <div class="grid no-print">
      <div class="panel">
        <h2>Thông tin bán</h2>
        <el-form label-position="top">
          <el-form-item label="Khách hàng">
            <el-select v-model="form.customer_id" clearable filterable style="width:100%">
              <el-option v-for="c in customers" :key="c.id" :label="c.full_name" :value="c.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="Thanh toán">
            <el-select v-model="form.payment_method" style="width:100%">
              <el-option label="Tiền mặt" value="CASH" />
              <el-option label="Thẻ" value="CARD" />
              <el-option label="Chuyển khoản" value="TRANSFER" />
            </el-select>
          </el-form-item>
          <div v-for="(it, idx) in form.items" :key="idx" class="line">
            <el-select v-model="it.ticket_type_id" style="flex:1.4">
              <el-option
                v-for="t in types"
                :key="t.id"
                :label="`${t.name} — ${formatMoney(t.price)}`"
                :value="t.id"
              />
            </el-select>
            <el-input-number v-model="it.quantity" :min="1" />
          </div>
          <el-button text type="primary" @click="addLine">+ Thêm loại vé</el-button>
          <div class="total">Tạm tính: <strong>{{ formatMoney(previewTotal()) }}</strong></div>
          <el-button type="primary" style="width:100%;margin-top:1rem" @click="checkout">
            Thanh toán
          </el-button>
        </el-form>
      </div>

      <div class="panel" v-if="lastInvoice">
        <div class="print-area">
          <h2>Hóa đơn #{{ lastInvoice.invoice_id }}</h2>
          <p>Thanh toán: {{ labelOf('payment', lastInvoice.lines?.[0]?.payment_method) }}</p>
          <el-table :data="lastInvoice.lines" size="small">
            <el-table-column prop="ticket_name" label="Loại vé" />
            <el-table-column prop="quantity" label="SL" width="70" />
            <el-table-column label="Đơn giá" width="120">
              <template #default="{ row }">{{ formatMoney(row.unit_price) }}</template>
            </el-table-column>
            <el-table-column label="Thành tiền" width="130">
              <template #default="{ row }">{{ formatMoney(row.line_amount) }}</template>
            </el-table-column>
          </el-table>
          <p class="total">Tổng: <strong>{{ formatMoney(lastInvoice.total_amount) }}</strong></p>
        </div>
        <el-button class="no-print" @click="printInvoice">In hóa đơn</el-button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.page-head h1 { margin: 0; font-family: var(--font-display); }
.muted { color: var(--muted); margin: 0.25rem 0 1rem; }
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.line { display: flex; gap: 0.5rem; margin-bottom: 0.5rem; }
.total { margin-top: 0.75rem; font-size: 1.05rem; }
@media (max-width: 900px) { .grid { grid-template-columns: 1fr; } }
</style>
