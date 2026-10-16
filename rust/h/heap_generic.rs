const MAX_OPERATIONS: usize = 512;
const MAX_ITEMS: usize = 128;
const ID_CAPACITY: usize = 4096;
const MAX_INPUT_LENGTH: usize = 1537;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hash_byte(hash: u64, byte: u8) -> u64 {
    (hash ^ byte as u64).wrapping_mul(FNV_PRIME)
}

fn hash_i32(mut hash: u64, value: i64) -> u64 {
    let bits = value as u32;
    for shift in [0, 8, 16, 24] {
        hash = hash_byte(hash, (bits >> shift) as u8);
    }
    hash
}

fn swap_items(ids: &mut [i64; MAX_ITEMS], priorities: &mut [i64; MAX_ITEMS],
              positions: &mut [i32; ID_CAPACITY], first: usize, second: usize) {
    ids.swap(first, second);
    priorities.swap(first, second);
    positions[ids[first] as usize] = first as i32;
    positions[ids[second] as usize] = second as i32;
}

fn heapify_up(ids: &mut [i64; MAX_ITEMS], priorities: &mut [i64; MAX_ITEMS],
              positions: &mut [i32; ID_CAPACITY], mut index: usize) {
    while index > 0 {
        let parent = (index - 1) / 2;
        if priorities[index] <= priorities[parent] { break; }
        swap_items(ids, priorities, positions, index, parent);
        index = parent;
    }
}

fn heapify_down(ids: &mut [i64; MAX_ITEMS], priorities: &mut [i64; MAX_ITEMS],
                positions: &mut [i32; ID_CAPACITY], heap_size: usize, mut index: usize) {
    loop {
        let mut best = index;
        let left = 2 * index + 1;
        let right = left + 1;
        if left < heap_size && priorities[left] > priorities[best] { best = left; }
        if right < heap_size && priorities[right] > priorities[best] { best = right; }
        if best == index { return; }
        swap_items(ids, priorities, positions, index, best);
        index = best;
    }
}

fn erase_item(ids: &mut [i64; MAX_ITEMS], priorities: &mut [i64; MAX_ITEMS],
              positions: &mut [i32; ID_CAPACITY], heap_size: &mut usize, item_id: usize) {
    let index = positions[item_id] as usize;
    let last = *heap_size - 1;
    positions[item_id] = -1;
    if index != last {
        ids[index] = ids[last];
        priorities[index] = priorities[last];
        positions[ids[index] as usize] = index as i32;
    }
    *heap_size = last;
    if index < *heap_size {
        heapify_up(ids, priorities, positions, index);
        heapify_down(ids, priorities, positions, *heap_size, index);
    }
}

#[no_mangle]
pub unsafe extern "C" fn heap_generic(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let operation_count_value = values[0];
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 ||
        length != 1 + 3 * operation_count_value as usize { return -1; }

    let mut ids = [0_i64; MAX_ITEMS];
    let mut priorities = [0_i64; MAX_ITEMS];
    let mut positions = [-1_i32; ID_CAPACITY];
    let mut used_ids = [false; ID_CAPACITY];
    let mut heap_size = 0;
    let mut hash = FNV_OFFSET;

    for operation in 0..operation_count_value as usize {
        let opcode = values[1 + 3 * operation];
        let item_id = values[2 + 3 * operation];
        let priority = values[3 + 3 * operation];
        let mut returned = None;

        if opcode == 0 {
            if item_id < 0 || item_id >= ID_CAPACITY as i64 || priority < i32::MIN as i64 ||
                priority > i32::MAX as i64 || used_ids[item_id as usize] || heap_size >= MAX_ITEMS {
                return -1;
            }
            if priorities[..heap_size].contains(&priority) { return -1; }
            used_ids[item_id as usize] = true;
            ids[heap_size] = item_id;
            priorities[heap_size] = priority;
            positions[item_id as usize] = heap_size as i32;
            heap_size += 1;
            heapify_up(&mut ids, &mut priorities, &mut positions, heap_size - 1);
        } else if opcode == 1 || opcode == 2 {
            if item_id != 0 || priority != 0 { return -1; }
            if heap_size > 0 {
                returned = Some((ids[0], priorities[0]));
                if opcode == 2 {
                    let top_id = ids[0] as usize;
                    erase_item(&mut ids, &mut priorities, &mut positions, &mut heap_size, top_id);
                }
            }
        } else if opcode == 3 {
            if item_id < 0 || item_id >= ID_CAPACITY as i64 || priority < i32::MIN as i64 ||
                priority > i32::MAX as i64 || positions[item_id as usize] < 0 { return -1; }
            let index = positions[item_id as usize] as usize;
            if (0..heap_size).any(|i| i != index && priorities[i] == priority) { return -1; }
            priorities[index] = priority;
            heapify_up(&mut ids, &mut priorities, &mut positions, index);
            heapify_down(&mut ids, &mut priorities, &mut positions, heap_size, index);
        } else if opcode == 4 {
            if item_id < 0 || item_id >= ID_CAPACITY as i64 || priority != 0 || positions[item_id as usize] < 0 {
                return -1;
            }
            erase_item(&mut ids, &mut priorities, &mut positions, &mut heap_size, item_id as usize);
        } else { return -1; }

        hash = hash_byte(hash, opcode as u8);
        hash = hash_byte(hash, u8::from(returned.is_some()));
        if let Some((returned_id, returned_priority)) = returned {
            hash = hash_i32(hash, returned_id);
            hash = hash_i32(hash, returned_priority);
        }
    }
    hash as i64
}
