<script setup>
import CrudPage from '../components/CrudPage.vue'
import { labelOf, labels } from '../labels'

const columns = [
  { prop: 'id', label: 'ID', width: 70 },
  { prop: 'name', label: 'Tên thường' },
  { prop: 'scientific_name', label: 'Tên khoa học' },
  { prop: 'class_group', label: 'Nhóm', formatter: (v) => labelOf('class_group', v), width: 110 },
  { prop: 'conservation_status', label: 'Bảo tồn', formatter: (v) => labelOf('conservation', v), width: 160 },
  { prop: 'diet', label: 'Chế độ ăn', formatter: (v) => labelOf('diet', v), width: 120 },
]

const fields = [
  { prop: 'name', label: 'Tên thường', required: true },
  { prop: 'scientific_name', label: 'Tên khoa học' },
  {
    prop: 'class_group',
    label: 'Nhóm',
    type: 'select',
    required: true,
    options: Object.entries(labels.class_group).map(([value, label]) => ({ value, label })),
  },
  {
    prop: 'conservation_status',
    label: 'Tình trạng bảo tồn',
    type: 'select',
    options: Object.entries(labels.conservation).map(([value, label]) => ({ value, label })),
  },
  {
    prop: 'diet',
    label: 'Chế độ ăn',
    type: 'select',
    required: true,
    options: Object.entries(labels.diet).map(([value, label]) => ({ value, label })),
  },
]
</script>

<template>
  <CrudPage
    table="species"
    title="Loài"
    :columns="columns"
    :fields="fields"
    :write-roles="['MANAGER', 'VET']"
  />
</template>
