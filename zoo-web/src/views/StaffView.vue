<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import CrudPage from '../components/CrudPage.vue'
import api, { crudApi } from '../api/client'
import { labelOf } from '../labels'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const positions = ref([])
const zones = ref([])
const enclosures = ref([])
const columns = ref([])
const fields = ref([])
const assignOpen = ref(false)
const assignForm = reactive({
  employee_id: null,
  enclosure_id: null,
  start_date: '',
  end_date: '',
  shift: 'MORNING',
})
const crudRef = ref(null)

onMounted(async () => {
  const [p, z, e] = await Promise.all([
    crudApi.list('positions', { page_size: 50 }),
    crudApi.list('zones', { page_size: 50 }),
    crudApi.list('enclosures', { page_size: 100 }),
  ])
  positions.value = p.items
  zones.value = z.items
  enclosures.value = e.items
  columns.value = [
    { prop: 'id', label: 'ID', width: 70 },
    { prop: 'full_name', label: 'Họ tên' },
    { prop: 'position_id', label: 'Chức danh', formatter: (v) => positions.value.find((x) => x.id === v)?.name || v },
    { prop: 'phone', label: 'Điện thoại', width: 130 },
    { prop: 'status', label: 'Trạng thái', formatter: (v) => labelOf('employee_status', v), width: 110 },
  ]
  fields.value = [
    { prop: 'full_name', label: 'Họ tên', required: true },
    {
      prop: 'gender',
      label: 'Giới tính',
      type: 'select',
      options: [
        { value: 'M', label: 'Nam' },
        { value: 'F', label: 'Nữ' },
      ],
    },
    { prop: 'phone', label: 'Điện thoại' },
    { prop: 'email', label: 'Email' },
    { prop: 'address', label: 'Địa chỉ' },
    { prop: 'hire_date', label: 'Ngày vào', type: 'date' },
    {
      prop: 'position_id',
      label: 'Chức danh',
      type: 'select',
      required: true,
      options: p.items.map((x) => ({ value: x.id, label: x.name })),
    },
    {
      prop: 'zone_id',
      label: 'Khu phụ trách',
      type: 'select',
      options: z.items.map((x) => ({ value: x.id, label: x.name })),
    },
    {
      prop: 'status',
      label: 'Trạng thái',
      type: 'select',
      options: [
        { value: 'ACTIVE', label: 'Đang làm' },
        { value: 'RESIGNED', label: 'Đã nghỉ' },
      ],
    },
  ]
})

function openAssign(row) {
  assignForm.employee_id = row.id
  assignForm.enclosure_id = null
  assignForm.start_date = new Date().toISOString().slice(0, 10)
  assignForm.end_date = ''
  assignForm.shift = 'MORNING'
  assignOpen.value = true
}

async function doAssign() {
  await api.post('/api/staff/assign', {
    ...assignForm,
    end_date: assignForm.end_date || null,
  })
  ElMessage.success('Đã phân công')
  assignOpen.value = false
}

async function resign(row) {
  await ElMessageBox.confirm(`Cho nghỉ việc ${row.full_name}?`, 'Xác nhận', { type: 'warning' })
  await api.post(`/api/staff/${row.id}/resign`)
  ElMessage.success('Đã cập nhật nghỉ việc')
  crudRef.value?.load()
}
</script>

<template>
  <div>
    <CrudPage
      v-if="fields.length"
      ref="crudRef"
      table="employees"
      title="Nhân viên"
      :columns="columns"
      :fields="fields"
      :write-roles="['MANAGER']"
    >
      <template #rowActions="{ row }">
        <template v-if="auth.can('MANAGER') && row.status === 'ACTIVE'">
          <el-button link type="primary" @click="openAssign(row)">Phân công</el-button>
          <el-button link type="danger" @click="resign(row)">Cho nghỉ</el-button>
        </template>
      </template>
    </CrudPage>

    <el-dialog v-model="assignOpen" title="Phân công chuồng" width="460px">
      <el-form label-position="top">
        <el-form-item label="Chuồng">
          <el-select v-model="assignForm.enclosure_id" filterable style="width: 100%">
            <el-option v-for="e in enclosures" :key="e.id" :label="e.name" :value="e.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="Từ ngày">
          <el-date-picker v-model="assignForm.start_date" type="date" value-format="YYYY-MM-DD" format="DD/MM/YYYY" style="width:100%" />
        </el-form-item>
        <el-form-item label="Đến ngày">
          <el-date-picker v-model="assignForm.end_date" type="date" value-format="YYYY-MM-DD" format="DD/MM/YYYY" style="width:100%" />
        </el-form-item>
        <el-form-item label="Ca">
          <el-select v-model="assignForm.shift" style="width: 100%">
            <el-option label="Ca sáng" value="MORNING" />
            <el-option label="Ca chiều" value="AFTERNOON" />
            <el-option label="Ca đêm" value="NIGHT" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="assignOpen = false">Hủy</el-button>
        <el-button type="primary" @click="doAssign">Lưu</el-button>
      </template>
    </el-dialog>
  </div>
</template>
