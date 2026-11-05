<script setup>
import { onMounted, ref } from 'vue'
import CrudPage from '../components/CrudPage.vue'
import { crudApi } from '../api/client'
import { formatDate } from '../utils/format'

const animals = ref([])
const vets = ref([])
const columns = ref([])
const fields = ref([])

onMounted(async () => {
  const [a, e] = await Promise.all([
    crudApi.list('animals', { page_size: 100 }),
    crudApi.list('employees', { page_size: 100 }),
  ])
  animals.value = a.items
  // position_id 2 = Veterinarian trong dữ liệu mẫu
  vets.value = e.items.filter((x) => x.position_id === 2)
  columns.value = [
    { prop: 'id', label: 'ID', width: 70 },
    { prop: 'animal_id', label: 'Động vật', formatter: (v) => animals.value.find((x) => x.id === v)?.name || v },
    { prop: 'vet_id', label: 'Bác sĩ', formatter: (v) => vets.value.find((x) => x.id === v)?.full_name || v },
    { prop: 'exam_date', label: 'Ngày khám', formatter: (v) => formatDate(v), width: 120 },
    { prop: 'diagnosis', label: 'Chẩn đoán' },
    { prop: 'follow_up_date', label: 'Tái khám', formatter: (v) => formatDate(v), width: 120 },
  ]
  fields.value = [
    {
      prop: 'animal_id',
      label: 'Động vật',
      type: 'select',
      required: true,
      options: a.items.map((x) => ({ value: x.id, label: x.name })),
    },
    {
      prop: 'vet_id',
      label: 'Bác sĩ thú y',
      type: 'select',
      required: true,
      options: vets.value.map((x) => ({ value: x.id, label: x.full_name })),
    },
    { prop: 'exam_date', label: 'Ngày khám', type: 'date' },
    { prop: 'diagnosis', label: 'Chẩn đoán' },
    { prop: 'treatment', label: 'Điều trị' },
    { prop: 'follow_up_date', label: 'Ngày tái khám', type: 'date' },
  ]
})
</script>

<template>
  <CrudPage
    v-if="fields.length"
    table="medical_records"
    title="Khám bệnh"
    :columns="columns"
    :fields="fields"
    :write-roles="['MANAGER', 'VET']"
  />
</template>
