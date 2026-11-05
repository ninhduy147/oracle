/** Map enum CSDL → nhãn tiếng Việt */
export const labels = {
  animal_status: {
    HEALTHY: 'Khỏe',
    SICK: 'Bệnh',
    QUARANTINE: 'Cách ly',
    DECEASED: 'Đã chết',
    TRANSFERRED: 'Đã chuyển đi',
  },
  enclosure_status: {
    ACTIVE: 'Hoạt động',
    MAINTENANCE: 'Bảo trì',
  },
  class_group: {
    MAMMAL: 'Thú',
    BIRD: 'Chim',
    REPTILE: 'Bò sát',
    AMPHIBIAN: 'Lưỡng cư',
    FISH: 'Cá',
  },
  conservation: {
    LC: 'Ít quan tâm (LC)',
    NT: 'Sắp bị đe dọa (NT)',
    VU: 'Sắp nguy cấp (VU)',
    EN: 'Nguy cấp (EN)',
    CR: 'Cực kỳ nguy cấp (CR)',
    EW: 'Tuyệt chủng trong tự nhiên (EW)',
  },
  diet: {
    CARNIVORE: 'Ăn thịt',
    HERBIVORE: 'Ăn cỏ',
    OMNIVORE: 'Ăn tạp',
  },
  gender: { M: 'Đực', F: 'Cái' },
  employee_status: { ACTIVE: 'Đang làm', RESIGNED: 'Đã nghỉ' },
  shift: { MORNING: 'Ca sáng', AFTERNOON: 'Ca chiều', NIGHT: 'Ca đêm' },
  food_category: { MEAT: 'Thịt', PLANT: 'Thực vật', MIXED: 'Hỗn hợp' },
  payment: { CASH: 'Tiền mặt', CARD: 'Thẻ', TRANSFER: 'Chuyển khoản' },
  role: {
    MANAGER: 'Quản lý',
    VET: 'Bác sĩ thú y',
    KEEPER: 'Người chăm sóc',
    CASHIER: 'Thu ngân',
  },
}

export function labelOf(group, value) {
  return labels[group]?.[value] ?? value ?? '—'
}
