const TABLE_CAPACITY: usize = 16;
const MAX_ACTIVE_ENTRIES: usize = 14;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_OPERATIONS;
const MAX_PROBE_DISTANCE: u32 = 64;
const GOLDEN_RATIO: u64 = 0x9E3779B97F4A7C15;

#[derive(Clone, Copy)]
struct Entry { key: u32, value: u32, psl: u32, occupied: bool }

struct RobinHoodMap { entries: [Entry; TABLE_CAPACITY], count: usize }

impl RobinHoodMap {
    fn new() -> Self {
        Self { entries: [Entry { key: 0, value: 0, psl: 0, occupied: false }; TABLE_CAPACITY], count: 0 }
    }

    fn hash_key(key: u32) -> usize {
        ((u64::from(key).wrapping_mul(GOLDEN_RATIO) >> 32) as usize) & (TABLE_CAPACITY - 1)
    }

    fn put(&mut self, key: u32, value: u32) -> bool {
        if (self.count * 100) / TABLE_CAPACITY >= 90 { return false; }
        let mut entry = Entry { key, value, psl: 0, occupied: true };
        let mut index = Self::hash_key(key);
        let mut probes = 0u32;
        while probes < MAX_PROBE_DISTANCE {
            let resident = &mut self.entries[index];
            if !resident.occupied {
                *resident = entry;
                self.count += 1;
                return true;
            }
            if resident.key == key {
                resident.value = value;
                return true;
            }
            if entry.psl > resident.psl { std::mem::swap(&mut entry, resident); }
            entry.psl += 1;
            index = (index + 1) & (TABLE_CAPACITY - 1);
            probes += 1;
        }
        false
    }

    fn get(&self, key: u32) -> Option<u32> {
        let mut index = Self::hash_key(key);
        let mut psl = 0u32;
        while psl < MAX_PROBE_DISTANCE {
            let resident = &self.entries[index];
            if !resident.occupied { return None; }
            if resident.key == key { return Some(resident.value); }
            if psl > resident.psl { return None; }
            index = (index + 1) & (TABLE_CAPACITY - 1);
            psl += 1;
        }
        None
    }

    fn backshift(&mut self, start: usize) {
        let mut index = start;
        for _ in 0..TABLE_CAPACITY {
            let next = (index + 1) & (TABLE_CAPACITY - 1);
            if !self.entries[next].occupied || self.entries[next].psl == 0 {
                self.entries[index].occupied = false;
                self.entries[index].psl = 0;
                return;
            }
            self.entries[index] = self.entries[next];
            self.entries[index].psl -= 1;
            index = next;
        }
    }

    fn remove(&mut self, key: u32) -> bool {
        let mut index = Self::hash_key(key);
        let mut psl = 0u32;
        while psl < MAX_PROBE_DISTANCE {
            let resident = &self.entries[index];
            if !resident.occupied { return false; }
            if resident.key == key {
                self.backshift(index);
                self.count -= 1;
                return true;
            }
            if psl > resident.psl { return false; }
            index = (index + 1) & (TABLE_CAPACITY - 1);
            psl += 1;
        }
        false
    }

    fn clear(&mut self) {
        for entry in &mut self.entries { entry.occupied = false; entry.psl = 0; }
        self.count = 0;
    }

    fn max_psl(&self) -> u32 {
        self.entries.iter().filter(|entry| entry.occupied).map(|entry| entry.psl).max().unwrap_or(0)
    }
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn robin_hood_hash(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_OPERATIONS as i64).contains(&values[0]) { return -1; }
    let operation_count = values[0] as usize;
    if length != 1 + 3 * operation_count { return -1; }

    let mut map = RobinHoodMap::new();
    let mut results = [0i64; MAX_OPERATIONS];
    for operation in 0..operation_count {
        let offset = 1 + 3 * operation;
        let opcode = values[offset];
        let raw_key = values[offset + 1];
        let raw_value = values[offset + 2];
        if opcode == 0 {
            if !(0..=u32::MAX as i64).contains(&raw_key) || !(100..=1_000_000).contains(&raw_value) { return -1; }
            if !map.put(raw_key as u32, raw_value as u32) || map.count > MAX_ACTIVE_ENTRIES { return -1; }
            results[operation] = -2;
        } else if opcode == 1 || opcode == 2 {
            if !(0..=u32::MAX as i64).contains(&raw_key) || raw_value != 0 { return -1; }
            let key = raw_key as u32;
            results[operation] = if opcode == 1 { map.get(key).map_or(-1, i64::from) } else { if map.remove(key) { 1 } else { 0 } };
        } else if (3..=7).contains(&opcode) {
            if raw_key != 0 || raw_value != 0 { return -1; }
            results[operation] = match opcode {
                3 => map.count as i64,
                4 => ((map.count * 100) / TABLE_CAPACITY) as i64,
                5 => map.max_psl() as i64,
                6 => { map.clear(); -3 },
                _ => if map.count == 0 { 1 } else { 0 },
            };
        } else { return -1; }
    }

    let output_bytes = operation_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OPERATIONS * 8];
    for operation in 0..operation_count { put_i64_le(&mut staged, operation * 8, results[operation]); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
