<script setup>
import { onMounted, ref } from 'vue'
import api from '../api/client'
import { formatDateTime } from '../utils/format'

const rows = ref([])
const total = ref(0)
const page = ref(1)

async function load() {
  const { data } = await api.get('/api/audit/logs', { params: { page: page.value, page_size: 20 } })
  rows.value = data.items
  total.value = data.total
}

onMounted(load)
</script>

<template>
  <section class="page">
    <header class="page-head">
      <div>
        <h1>Nhật ký hệ thống</h1>
        <p class="muted">Chỉ quản lý — bảng audit_logs</p>
      </div>
    </header>
    <div class="panel">
      <el-table :data="rows" stripe>
        <el-table-column prop="id" label="ID" width="70" />
        <el-table-column prop="table_name" label="Bảng" width="140" />
        <el-table-column prop="action" label="Hành động" width="110" />
        <el-table-column prop="record_id" label="Bản ghi" width="100" />
        <el-table-column prop="db_user" label="User DB" width="110" />
        <el-table-column label="Thời điểm" width="160">
          <template #default="{ row }">{{ formatDateTime(row.created_at) }}</template>
        </el-table-column>
        <el-table-column prop="details" label="Chi tiết" />
      </el-table>
      <div class="pager">
        <el-pagination
          background
          layout="total, prev, pager, next"
          :total="total"
          :page-size="20"
          v-model:current-page="page"
          @current-change="load"
        />
      </div>
    </div>
  </section>
</template>

<style scoped>
.page-head h1 { margin: 0; font-family: var(--font-display); }
.muted { color: var(--muted); margin: 0.25rem 0 1rem; }
.pager { display: flex; justify-content: flex-end; margin-top: 1rem; }
</style>
