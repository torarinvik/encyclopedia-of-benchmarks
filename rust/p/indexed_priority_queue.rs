const MAX_EVENTS: usize = 256;
const MAX_ACTIVE: usize = 64;
const MAX_INPUT_VALUES: usize = 1538;

unsafe fn store_i64_le(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(position + byte) = (bits >> (byte * 8)) as u8;
    }
}

fn key_in_use(heap_ids: &[i64; MAX_ACTIVE], heap_keys: &[i64; MAX_ACTIVE],
              size: usize, key: i64, except_id: i64) -> bool {
    (0..size).any(|index| heap_ids[index] != except_id && heap_keys[index] == key)
}

fn sift_up(heap_ids: &mut [i64; MAX_ACTIVE], heap_keys: &mut [i64; MAX_ACTIVE],
           positions: &mut [i32; MAX_ACTIVE], index_value: usize) -> bool {
    let mut index = index_value;
    let original = index;
    let item_id = heap_ids[index];
    let item_key = heap_keys[index];
    while index > 0 {
        let parent = (index - 1) / 2;
        if item_key >= heap_keys[parent] { break; }
        heap_ids[index] = heap_ids[parent];
        heap_keys[index] = heap_keys[parent];
        positions[heap_ids[index] as usize] = index as i32;
        index = parent;
    }
    heap_ids[index] = item_id;
    heap_keys[index] = item_key;
    positions[item_id as usize] = index as i32;
    index != original
}

fn sift_down(heap_ids: &mut [i64; MAX_ACTIVE], heap_keys: &mut [i64; MAX_ACTIVE],
             positions: &mut [i32; MAX_ACTIVE], size: usize, index_value: usize) {
    let mut index = index_value;
    let item_id = heap_ids[index];
    let item_key = heap_keys[index];
    let half = size / 2;
    while index < half {
        let mut child = index * 2 + 1;
        let right = child + 1;
        if right < size && heap_keys[child] > heap_keys[right] { child = right; }
        if item_key <= heap_keys[child] { break; }
        heap_ids[index] = heap_ids[child];
        heap_keys[index] = heap_keys[child];
        positions[heap_ids[index] as usize] = index as i32;
        index = child;
    }
    heap_ids[index] = item_id;
    heap_keys[index] = item_key;
    positions[item_id as usize] = index as i32;
}

fn remove_at(size: &mut usize, heap_ids: &mut [i64; MAX_ACTIVE], heap_keys: &mut [i64; MAX_ACTIVE],
             positions: &mut [i32; MAX_ACTIVE], index: usize) {
    let new_size = *size - 1;
    let removed_id = heap_ids[index];
    let moved_id = heap_ids[new_size];
    let moved_key = heap_keys[new_size];
    *size = new_size;
    positions[removed_id as usize] = -1;
    if index == new_size { return; }
    heap_ids[index] = moved_id;
    heap_keys[index] = moved_key;
    positions[moved_id as usize] = index as i32;
    if !sift_up(heap_ids, heap_keys, positions, index) {
        sift_down(heap_ids, heap_keys, positions, *size, index);
    }
}

#[no_mangle]
pub unsafe extern "C" fn indexed_priority_queue(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(1..=MAX_INPUT_VALUES).contains(&length) { return -1; }
    let event_count_value = *values;
    if !(0..=MAX_EVENTS as i64).contains(&event_count_value) { return -1; }
    let event_count = event_count_value as usize;
    if length != 1 + 6 * event_count { return -1; }
    if event_count == 0 { return 0; }

    let mut heap_ids = [0_i64; MAX_ACTIVE];
    let mut heap_keys = [0_i64; MAX_ACTIVE];
    let mut positions = [-1_i32; MAX_ACTIVE];
    let mut records = [[0_i64; 6]; MAX_EVENTS];
    let mut size = 0_usize;

    for event_index in 0..event_count {
        let start = 1 + event_index * 6;
        let opcode = *values.add(start);
        let element_id = *values.add(start + 1);
        let key = *values.add(start + 2);
        if *values.add(start + 3) != 0 || *values.add(start + 4) != 0 || *values.add(start + 5) != 0 { return -1; }
        let mut status = 1_i64;
        let mut result_id = 0_i64;
        let mut result_key = 0_i64;

        if opcode == 0 {
            if !(0..MAX_ACTIVE as i64).contains(&element_id) || !(i32::MIN as i64..=i32::MAX as i64).contains(&key) { return -1; }
            let id = element_id as usize;
            if positions[id] >= 0 || size >= MAX_ACTIVE || key_in_use(&heap_ids, &heap_keys, size, key, -1) { return -1; }
            heap_ids[size] = element_id;
            heap_keys[size] = key;
            positions[id] = size as i32;
            size += 1;
            let _ = sift_up(&mut heap_ids, &mut heap_keys, &mut positions, size - 1);
        } else if opcode == 1 || opcode == 2 {
            if element_id != 0 || key != 0 { return -1; }
            if size == 0 { status = 0; }
            else {
                result_id = heap_ids[0];
                result_key = heap_keys[0];
                if opcode == 2 { remove_at(&mut size, &mut heap_ids, &mut heap_keys, &mut positions, 0); }
            }
        } else if opcode == 3 || opcode == 4 {
            if !(0..MAX_ACTIVE as i64).contains(&element_id) || key != 0 { return -1; }
            let position = positions[element_id as usize];
            status = if position >= 0 { 1 } else { 0 };
            if opcode == 3 && position >= 0 {
                remove_at(&mut size, &mut heap_ids, &mut heap_keys, &mut positions, position as usize);
            }
        } else if (5..=7).contains(&opcode) {
            if !(0..MAX_ACTIVE as i64).contains(&element_id) || !(i32::MIN as i64..=i32::MAX as i64).contains(&key) { return -1; }
            let position = positions[element_id as usize];
            if position < 0 { return -1; }
            let position = position as usize;
            let old_key = heap_keys[position];
            if (opcode == 6 && key >= old_key) || (opcode == 7 && key <= old_key)
                || key_in_use(&heap_ids, &heap_keys, size, key, element_id) { return -1; }
            heap_keys[position] = key;
            if opcode == 6 {
                let _ = sift_up(&mut heap_ids, &mut heap_keys, &mut positions, position);
            } else if opcode == 7 {
                sift_down(&mut heap_ids, &mut heap_keys, &mut positions, size, position);
            } else if !sift_up(&mut heap_ids, &mut heap_keys, &mut positions, position) {
                sift_down(&mut heap_ids, &mut heap_keys, &mut positions, size, position);
            }
        } else if opcode == 8 || opcode == 9 || opcode == 10 {
            if element_id != 0 || key != 0 { return -1; }
            if opcode == 8 {
                for index in 0..size { positions[heap_ids[index] as usize] = -1; }
                size = 0;
            } else if opcode == 9 {
                result_id = size as i64;
            } else {
                result_id = if size == 0 { 1 } else { 0 };
            }
        } else { return -1; }

        records[event_index] = [status, result_id, result_key, size as i64,
            if size == 0 { 0 } else { heap_ids[0] },
            if size == 0 { 0 } else { heap_keys[0] }];
    }

    let required = event_count * 48;
    if output.is_null() || output_capacity < required { return -2; }
    for event in 0..event_count {
        for field in 0..6 { store_i64_le(output, event * 48 + field * 8, records[event][field]); }
    }
    required as i64
}
