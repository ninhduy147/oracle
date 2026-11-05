<script setup>
import { onMounted, ref } from 'vue'
import CrudPage from '../components/CrudPage.vue'
import { crudApi } from '../api/client'
import { labelOf } from '../labels'

const zones = ref([])
const columns = ref([])
const fields = ref([])

onMounted(async () => {
  const z = await crudApi.list('zones', { page_size: 100 })
  zones.value = z.items
  columns.value = [
    { prop: 'id', label: 'ID', width: 70 },
    { prop: 'name', label: 'Tên chuồng' },
    { prop: 'zone_id', label: 'Khu', formatter: (v) => zones.value.find((x) => x.id === v)?.name || v },
    { prop: 'capacity', label: 'Sức chứa', width: 100 },
    { prop: 'status', label: 'Trạng thái', formatter: (v) => labelOf('enclosure_status', v), width: 120 },
  ]
  fields.value = [
    { prop: 'name', label: 'Tên chuồng', required: true },
    {
      prop: 'zone_id',
      label: 'Khu vực',
      type: 'select',
      required: true,
      options: z.items.map((x) => ({ value: x.id, label: x.name })),
    },
    { prop: 'capacity', label: 'Sức chứa', type: 'number', required: true },
    {
      prop: 'status',
      label: 'Trạng thái',
      type: 'select',
      options: [
        { value: 'ACTIVE', label: 'Hoạt động' },
        { value: 'MAINTENANCE', label: 'Bảo trì' },
      ],
    },
  ]
})
</script>

<template>
  <CrudPage
    v-if="fields.length"
    table="enclosures"
    title="Chuồng"
    :columns="columns"
    :fields="fields"
    :write-roles="['MANAGER']"
  />
</template>
