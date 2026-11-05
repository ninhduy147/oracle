<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { crudApi } from '../api/client'
import { useAuthStore } from '../stores/auth'

const props = defineProps({
  table: { type: String, required: true },
  title: { type: String, required: true },
  columns: { type: Array, required: true },
  /** fields for form: { prop, label, type, options?, required? } */
  fields: { type: Array, required: true },
  writeRoles: { type: Array, default: () => ['MANAGER'] },
  pageSize: { type: Number, default: 10 },
})

const emit = defineEmits(['loaded'])
const auth = useAuthStore()
const loading = ref(false)
const rows = ref([])
const total = ref(0)
const page = ref(1)
const q = ref('')
const dialog = ref(false)
const editingId = ref(null)
const form = reactive({})

const canWrite = computed(() => props.writeRoles.includes(auth.role))

function resetForm() {
  props.fields.forEach((f) => {
    form[f.prop] = f.default ?? (f.type === 'number' ? null : '')
  })
}

async function load() {
  loading.value = true
  try {
    const data = await crudApi.list(props.table, {
      q: q.value || undefined,
      page: page.value,
      page_size: props.pageSize,
    })
    rows.value = data.items
    total.value = data.total
    emit('loaded', data)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  editingId.value = null
  resetForm()
  dialog.value = true
}

function openEdit(row) {
  editingId.value = row.id
  props.fields.forEach((f) => {
    form[f.prop] = row[f.prop] ?? ''
  })
  dialog.value = true
}

async function save() {
  const body = {}
  props.fields.forEach((f) => {
    let v = form[f.prop]
    if (v === '') v = null
    body[f.prop] = v
  })
  if (editingId.value) {
    await crudApi.update(props.table, editingId.value, body)
    ElMessage.success('Đã cập nhật')
  } else {
    await crudApi.create(props.table, body)
    ElMessage.success('Đã thêm')
  }
  dialog.value = false
  await load()
}

async function remove(row) {
  await ElMessageBox.confirm(`Xóa bản ghi #${row.id}?`, 'Xác nhận', {
    type: 'warning',
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy',
  })
  await crudApi.remove(props.table, row.id)
  ElMessage.success('Đã xóa')
  await load()
}

onMounted(load)

defineExpose({ load, rows })
</script>

<template>
  <section class="page">
    <header class="page-head">
      <div>
        <h1>{{ title }}</h1>
        <p class="muted">Quản lý dữ liệu bảng {{ table }}</p>
      </div>
      <div class="actions">
        <el-input
          v-model="q"
          clearable
          placeholder="Tìm kiếm…"
          style="width: 220px"
          @keyup.enter="page = 1; load()"
          @clear="page = 1; load()"
        />
        <el-button @click="page = 1; load()">Tìm</el-button>
        <el-button v-if="canWrite" type="primary" @click="openCreate">Thêm</el-button>
      </div>
    </header>

    <el-table :data="rows" v-loading="loading" stripe empty-text="Không có dữ liệu">
      <el-table-column
        v-for="col in columns"
        :key="col.prop"
        :prop="col.prop"
        :label="col.label"
        :min-width="col.width || 120"
      >
        <template #default="{ row }">
          <slot :name="`col-${col.prop}`" :row="row">
            {{ col.formatter ? col.formatter(row[col.prop], row) : row[col.prop] }}
          </slot>
        </template>
      </el-table-column>
      <el-table-column v-if="canWrite || $slots.rowActions" label="Thao tác" width="200" fixed="right">
        <template #default="{ row }">
          <slot name="rowActions" :row="row" />
          <el-button v-if="canWrite" link type="primary" @click="openEdit(row)">Sửa</el-button>
          <el-button v-if="canWrite && auth.role === 'MANAGER'" link type="danger" @click="remove(row)">Xóa</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pager">
      <el-pagination
        background
        layout="total, prev, pager, next"
        :total="total"
        :page-size="pageSize"
        v-model:current-page="page"
        @current-change="load"
      />
    </div>

    <el-dialog v-model="dialog" :title="editingId ? 'Sửa' : 'Thêm mới'" width="520px" destroy-on-close>
      <el-form label-position="top">
        <el-form-item v-for="f in fields" :key="f.prop" :label="f.label" :required="f.required">
          <el-select v-if="f.type === 'select'" v-model="form[f.prop]" filterable clearable style="width: 100%">
            <el-option v-for="o in f.options" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
          <el-input-number v-else-if="f.type === 'number'" v-model="form[f.prop]" style="width: 100%" />
          <el-date-picker
            v-else-if="f.type === 'date'"
            v-model="form[f.prop]"
            type="date"
            value-format="YYYY-MM-DD"
            format="DD/MM/YYYY"
            style="width: 100%"
          />
          <el-input v-else v-model="form[f.prop]" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog = false">Hủy</el-button>
        <el-button type="primary" @click="save">Lưu</el-button>
      </template>
    </el-dialog>
  </section>
</template>

<style scoped>
.page-head {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  justify-content: space-between;
  align-items: end;
  margin-bottom: 1.25rem;
}
.page-head h1 {
  margin: 0;
  font-family: var(--font-display);
  font-size: 1.75rem;
  color: var(--ink);
}
.muted { margin: 0.25rem 0 0; color: var(--muted); }
.actions { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; }
.pager { display: flex; justify-content: flex-end; margin-top: 1rem; }
</style>
