<script setup>
import CrudPage from '../components/CrudPage.vue'

const columns = [
  { prop: 'id', label: 'ID', width: 70 },
  { prop: 'name', label: 'Tên khu' },
  { prop: 'description', label: 'Mô tả' },
  { prop: 'area_m2', label: 'Diện tích (m²)', width: 130 },
]
const fields = [
  { prop: 'name', label: 'Tên khu', required: true },
  { prop: 'description', label: 'Mô tả' },
  { prop: 'area_m2', label: 'Diện tích (m²)', type: 'number' },
]
</script>

<template>
  <CrudPage table="zones" title="Khu vực" :columns="columns" :fields="fields" :write-roles="['MANAGER']" />
</template>
