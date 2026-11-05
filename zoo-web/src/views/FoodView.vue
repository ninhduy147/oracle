<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import CrudPage from '../components/CrudPage.vue'
import api, { crudApi } from '../api/client'
import { labelOf, labels } from '../labels'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const animals = ref([])
const foods = ref([])
const suppliers = ref([])
const feedOpen = ref(false)
const poOpen = ref(false)
const feed = reactive({ animal_id: null, food_id: null, quantity: 1, note: '' })
const po = reactive({
  supplier_id: null,
  items: [{ food_id: null, quantity: 1, unit_price: 0, expiry_date: '' }],
})

const columns = [
  { prop: 'id', label: 'ID', width: 70 },
  { prop: 'name', label: 'Tên' },
  { prop: 'category', label: 'Loại', formatter: (v) => labelOf('food_category', v), width: 110 },
  { prop: 'unit', label: 'Đơn vị', width: 90 },
  { prop: 'stock_qty', label: 'Tồn', width: 90 },
  { prop: 'min_stock', label: 'Tối thiểu', width: 100 },
]
const fields = [
  { prop: 'name', label: 'Tên', required: true },
  {
    prop: 'category',
    label: 'Loại',
    type: 'select',
    required: true,
    options: Object.entries(labels.food_category).map(([value, label]) => ({ value, label })),
  },
  { prop: 'unit', label: 'Đơn vị', required: true, default: 'kg' },
  { prop: 'stock_qty', label: 'Tồn kho', type: 'number', default: 0 },
  { prop: 'min_stock', label: 'Tồn tối thiểu', type: 'number', default: 10 },
]

onMounted(async () => {
  const [a, f, s] = await Promise.all([
    crudApi.list('animals', { page_size: 100 }),
    crudApi.list('foods', { page_size: 100 }),
    crudApi.list('suppliers', { page_size: 50 }),
  ])
  animals.value = a.items
  foods.value = f.items
  suppliers.value = s.items
})

async function doFeed() {
  await api.post('/api/food/feed', { ...feed })
  ElMessage.success('Đã ghi nhận cho ăn')
  feedOpen.value = false
}

function addPoLine() {
  po.items.push({ food_id: null, quantity: 1, unit_price: 0, expiry_date: '' })
}

async function doPo() {
  await api.post('/api/food/purchase-orders', {
    supplier_id: po.supplier_id,
    items: po.items.map((i) => ({
      ...i,
      expiry_date: i.expiry_date || null,
    })),
  })
  ElMessage.success('Đã nhập kho (trigger cộng tồn)')
  poOpen.value = false
}
</script>

<template>
  <div>
    <div class="toolbar no-print" v-if="auth.can('MANAGER', 'KEEPER')">
      <el-button type="success" @click="feedOpen = true">Cho ăn</el-button>
      <el-button type="primary" @click="poOpen = true">Phiếu nhập kho</el-button>
    </div>
    <CrudPage
      table="foods"
      title="Thức ăn & kho"
      :columns="columns"
      :fields="fields"
      :write-roles="['MANAGER', 'KEEPER']"
    />

    <el-dialog v-model="feedOpen" title="Cho động vật ăn" width="460px">
      <el-form label-position="top">
        <el-form-item label="Động vật">
          <el-select v-model="feed.animal_id" filterable style="width:100%">
            <el-option v-for="a in animals" :key="a.id" :label="a.name" :value="a.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="Thức ăn">
          <el-select v-model="feed.food_id" filterable style="width:100%">
            <el-option v-for="f in foods" :key="f.id" :label="`${f.name} (tồn ${f.stock_qty})`" :value="f.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="Số lượng">
          <el-input-number v-model="feed.quantity" :min="0.1" :step="0.5" style="width:100%" />
        </el-form-item>
        <el-form-item label="Ghi chú">
          <el-input v-model="feed.note" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="feedOpen = false">Hủy</el-button>
        <el-button type="primary" @click="doFeed">Xác nhận</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="poOpen" title="Phiếu nhập nhiều dòng" width="640px">
      <el-form label-position="top">
        <el-form-item label="Nhà cung cấp">
          <el-select v-model="po.supplier_id" filterable style="width:100%">
            <el-option v-for="s in suppliers" :key="s.id" :label="s.name" :value="s.id" />
          </el-select>
        </el-form-item>
        <div v-for="(it, idx) in po.items" :key="idx" class="po-line">
          <el-select v-model="it.food_id" placeholder="Thức ăn" filterable style="flex:1.4">
            <el-option v-for="f in foods" :key="f.id" :label="f.name" :value="f.id" />
          </el-select>
          <el-input-number v-model="it.quantity" :min="0.1" placeholder="SL" />
          <el-input-number v-model="it.unit_price" :min="0" :step="1000" placeholder="Đơn giá" />
        </div>
        <el-button text type="primary" @click="addPoLine">+ Thêm dòng</el-button>
      </el-form>
      <template #footer>
        <el-button @click="poOpen = false">Hủy</el-button>
        <el-button type="primary" @click="doPo">Nhập kho</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.toolbar { display: flex; gap: 0.5rem; margin-bottom: 0.75rem; }
.po-line { display: flex; gap: 0.5rem; margin-bottom: 0.5rem; flex-wrap: wrap; }
</style>
