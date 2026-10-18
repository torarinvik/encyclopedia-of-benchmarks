const MAX_OPERATIONS: usize = 24;
const MAX_INITIAL_CAPACITY: usize = 8;
const MAX_TABLE_CAPACITY: usize = 64;
const MAX_INPUT_LENGTH: usize = 51;
const MAX_INSERTS_TO_CAPACITY_64: usize = MAX_TABLE_CAPACITY / 4;
const MAX_OUTPUT_ELEMENTS: usize = 3 + (MAX_OPERATIONS - MAX_INSERTS_TO_CAPACITY_64) + MAX_TABLE_CAPACITY;
const MAX_OUTPUT_BYTES: usize = MAX_OUTPUT_ELEMENTS * 8;

const OP_INSERT: i64 = 0;
const OP_REMOVE: i64 = 1;
const OP_FIND: i64 = 2;

struct Table {
    slots: [i64; MAX_TABLE_CAPACITY],
    capacity: usize,
    size: usize,
}

fn probe_insert(table: &Table, key: i64) -> Option<usize> {
    for probe in 0..table.capacity * 100 {
        // The benchmark normatively defines hash(key)=key.
        let index = (key as usize + probe * probe) % table.capacity;
        if table.slots[index] == 0 || table.slots[index] == -1 { return Some(index); }
    }
    None
}

fn probe_find(table: &Table, key: i64) -> Option<usize> {
    for probe in 0..table.capacity * 100 {
        let index = (key as usize + probe * probe) % table.capacity;
        let slot = table.slots[index];
        if slot == 0 { return None; }
        if slot == key { return Some(index); }
    }
    None
}

fn rehash(table: &mut Table) -> bool {
    let old_capacity = table.capacity;
    if old_capacity > MAX_TABLE_CAPACITY / 2 { return false; }
    let old_slots = table.slots;
    let new_capacity = old_capacity * 2;
    table.slots.fill(0);
    table.capacity = new_capacity;

    // Reinsertion follows add(), which can recursively trigger rehash again.
    for key in old_slots[..old_capacity].iter().copied() {
        if key == 0 || key == -1 { continue; }
        if table.size == 0 { return false; }
        table.size -= 1;
        if !insert_key(table, key) { return false; }
    }
    true
}

fn insert_key(table: &mut Table, key: i64) -> bool {
    let Some(index) = probe_insert(table, key) else { return false; };
    table.slots[index] = key;
    table.size += 1;
    if table.size * 2 >= table.capacity { return rehash(table); }
    true
}

fn write_i64_le(output: &mut [u8], offset: &mut usize, value: i64) {
    output[*offset..*offset + 8].copy_from_slice(&value.to_le_bytes());
    *offset += 8;
}

#[no_mangle]
pub unsafe extern "C" fn quadratic_probing_hash_table(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_INITIAL_CAPACITY as i64 ||
        values[1] < 0 || values[1] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[1] as usize;
    if input_length != 2 + 2 * operation_count { return -1; }

    let mut table = Table { slots: [0; MAX_TABLE_CAPACITY], capacity: values[0] as usize, size: 0 };
    let mut active = [false; MAX_TABLE_CAPACITY + 1];
    let mut find_results = [0_i64; MAX_OPERATIONS];
    let mut find_count = 0_usize;

    for operation_index in 0..operation_count {
        let operation = values[2 + 2 * operation_index];
        let key = values[3 + 2 * operation_index];
        if operation < OP_INSERT || operation > OP_FIND || !(1..=64).contains(&key) { return -1; }
        let key_index = key as usize;

        if operation == OP_INSERT {
            if active[key_index] || !insert_key(&mut table, key) { return -1; }
            active[key_index] = true;
        } else if operation == OP_REMOVE {
            if !active[key_index] { return -1; }
            let Some(index) = probe_find(&table, key) else { return -1; };
            table.slots[index] = -1;
            active[key_index] = false;
            table.size -= 1;
        } else {
            let index = probe_find(&table, key);
            // Source find() uses index zero as its not-present sentinel.
            find_results[find_count] = match index {
                Some(0) | None => 0,
                Some(index) => table.slots[index],
            };
            find_count += 1;
        }
    }

    let output_elements = 3 + find_count + table.capacity;
    let output_bytes = output_elements * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    let mut offset = 0_usize;
    write_i64_le(output_slice, &mut offset, table.capacity as i64);
    write_i64_le(output_slice, &mut offset, table.size as i64);
    write_i64_le(output_slice, &mut offset, find_count as i64);
    for result in find_results[..find_count].iter().copied() {
        write_i64_le(output_slice, &mut offset, result);
    }
    for slot in table.slots[..table.capacity].iter().copied() {
        write_i64_le(output_slice, &mut offset, slot);
    }
    output_bytes as i64
}
