<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import CrudPage from '../components/CrudPage.vue'
import api, { crudApi } from '../api/client'
import { labelOf } from '../labels'
import { formatDate } from '../utils/format'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const species = ref([])
const enclosures = ref([])
const moveOpen = ref(false)
const moveAnimalId = ref(null)
const moveEnc = ref(null)
const crudRef = ref(null)

const columns = [
  { prop: 'id', label: 'ID', width: 70 },
  { prop: 'name', label: 'Tên' },
  { prop: 'species_id', label: 'Loài', formatter: (v) => species.value.find((s) => s.id === v)?.name || v },
  { prop: 'enclosure_id', label: 'Chuồng', formatter: (v) => enclosures.value.find((e) => e.id === v)?.name || v },
  { prop: 'gender', label: 'Giới tính', formatter: (v) => labelOf('gender', v), width: 100 },
  { prop: 'status', label: 'Trạng thái', formatter: (v) => labelOf('animal_status', v), width: 120 },
  { prop: 'weight_kg', label: 'Kg', width: 80 },
  { prop: 'arrival_date', label: 'Ngày đến', formatter: (v) => formatDate(v), width: 120 },
]

const fields = ref([])

onMounted(async () => {
  const [s, e] = await Promise.all([
    crudApi.list('species', { page_size: 100 }),
    crudApi.list('enclosures', { page_size: 100 }),
  ])
  species.value = s.items
  enclosures.value = e.items
  fields.value = [
    { prop: 'name', label: 'Tên', required: true },
    {
      prop: 'species_id',
      label: 'Loài',
      type: 'select',
      required: true,
      options: s.items.map((x) => ({ value: x.id, label: x.name })),
    },
    {
      prop: 'enclosure_id',
      label: 'Chuồng',
      type: 'select',
      options: e.items.map((x) => ({ value: x.id, label: `${x.name} (${labelOf('enclosure_status', x.status)})` })),
    },
    {
      prop: 'gender',
      label: 'Giới tính',
      type: 'select',
      options: [
        { value: 'M', label: 'Đực' },
        { value: 'F', label: 'Cái' },
      ],
    },
    { prop: 'birth_date', label: 'Ngày sinh', type: 'date' },
    { prop: 'arrival_date', label: 'Ngày đến', type: 'date' },
    { prop: 'origin', label: 'Nguồn gốc' },
    { prop: 'weight_kg', label: 'Cân nặng (kg)', type: 'number' },
    {
      prop: 'status',
      label: 'Trạng thái',
      type: 'select',
      options: [
        { value: 'HEALTHY', label: 'Khỏe' },
        { value: 'SICK', label: 'Bệnh' },
        { value: 'QUARANTINE', label: 'Cách ly' },
        { value: 'DECEASED', label: 'Đã chết' },
        { value: 'TRANSFERRED', label: 'Đã chuyển đi' },
      ],
    },
  ]
})

function openMove(row) {
  moveAnimalId.value = row.id
  moveEnc.value = row.enclosure_id
  moveOpen.value = true
}

async function doMove() {
  await api.post(`/api/animals/${moveAnimalId.value}/move`, { enclosure_id: moveEnc.value })
  ElMessage.success('Đã chuyển chuồng')
  moveOpen.value = false
  crudRef.value?.load()
}
</script>

<template>
  <div>
    <CrudPage
      v-if="fields.length"
      ref="crudRef"
      table="animals"
      title="Động vật"
      :columns="columns"
      :fields="fields"
      :write-roles="['MANAGER', 'VET', 'KEEPER']"
    >
      <template #rowActions="{ row }">
        <el-button
          v-if="auth.can('MANAGER', 'KEEPER', 'VET')"
          link
          type="warning"
          @click="openMove(row)"
        >
          Chuyển chuồng
        </el-button>
      </template>
    </CrudPage>

    <el-dialog v-model="moveOpen" title="Chuyển chuồng" width="420px">
      <el-form label-position="top">
        <el-form-item label="Chuồng đích">
          <el-select v-model="moveEnc" style="width: 100%" filterable>
            <el-option
              v-for="e in enclosures"
              :key="e.id"
              :label="`${e.name} — ${labelOf('enclosure_status', e.status)}`"
              :value="e.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="moveOpen = false">Hủy</el-button>
        <el-button type="primary" @click="doMove">Chuyển</el-button>
      </template>
    </el-dialog>
  </div>
</template>
