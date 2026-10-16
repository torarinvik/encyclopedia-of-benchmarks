const MAX_OPERATIONS: usize = 256;
const MAX_KEYS: usize = 64;
const MAX_CAPACITY: usize = 1024;
const VALUE_OFFSET: i64 = 1_000_001;

#[derive(Clone, Copy, Default)]
struct Entry { state: u8, key: i64, value: i64 }

fn place(table: &mut [Entry; MAX_CAPACITY], capacity: usize, key: i64, value: i64) {
    let mut index = (key % capacity as i64) as usize;
    for _ in 0..capacity {
        if table[index].state != 1 { table[index] = Entry { state: 1, key, value }; return; }
        if table[index].key == key { table[index].value = value; return; }
        index = (index + 1) % capacity;
    }
}

fn resize(table: &mut [Entry; MAX_CAPACITY], capacity: &mut usize, next: usize, size: &mut usize) {
    let old = *table;
    let old_capacity = *capacity;
    for slot in table.iter_mut().take(next) { *slot = Entry::default(); }
    *capacity = next;
    *size = 0;
    for entry in old.iter().take(old_capacity) {
        if entry.state == 1 { place(table, next, entry.key, entry.value); *size += 1; }
    }
}

fn find(table: &[Entry; MAX_CAPACITY], capacity: usize, key: i64) -> (usize, usize, bool) {
    let mut index = (key % capacity as i64) as usize;
    let mut tombstone = capacity;
    for _ in 0..capacity {
        if table[index].state == 0 { return (capacity, tombstone, false); }
        if table[index].state == 2 { if tombstone == capacity { tombstone = index; } }
        else if table[index].key == key { return (index, tombstone, tombstone != capacity); }
        index = (index + 1) % capacity;
    }
    (capacity, tombstone, false)
}

#[no_mangle]
pub extern "C" fn hash_map_open_addressing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 1 + 3 * MAX_OPERATIONS { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let q = values[0];
    if q < 0 || q as usize > MAX_OPERATIONS || length != 1 + 3 * q as usize { return -1; }
    let mut table = [Entry::default(); MAX_CAPACITY];
    let (mut capacity, mut size) = (8usize, 0usize);
    let (mut query_sum, mut query_index) = (0i64, 0i64);

    for opi in 0..q as usize {
        let opcode = values[1 + 3 * opi];
        let key = values[2 + 3 * opi];
        let value = values[3 + 3 * opi];
        if opcode == 0 {
            if !(0..=1_000_000).contains(&key) || !(-1_000_000..=1_000_000).contains(&value) { return -1; }
            let (before, _, _) = find(&table, capacity, key);
            if before == capacity && size >= MAX_KEYS { return -1; }
            if size >= capacity * 3 / 4 {
                if capacity * 2 > MAX_CAPACITY { return -1; }
                let next_capacity = capacity * 2;
                resize(&mut table, &mut capacity, next_capacity, &mut size);
            }
            let (found, tombstone, tomb_before) = find(&table, capacity, key);
            if found != capacity {
                if tomb_before { return -1; }
                table[found].value = value;
            } else {
                let mut index = (key % capacity as i64) as usize;
                let mut target = tombstone;
                for _ in 0..capacity {
                    if table[index].state == 0 { if target == capacity { target = index; } break; }
                    index = (index + 1) % capacity;
                }
                if target == capacity { return -1; }
                table[target] = Entry { state: 1, key, value };
                size += 1;
            }
        } else if opcode == 1 || opcode == 2 || opcode == 3 {
            if !(0..=1_000_000).contains(&key) || value != 0 { return -1; }
            let (found, _, _) = find(&table, capacity, key);
            if (opcode == 1 || opcode == 2) && found == capacity { return -1; }
            if opcode == 1 {
                query_index += 1;
                query_sum += query_index * (table[found].value + VALUE_OFFSET);
            } else if opcode == 2 {
                table[found].state = 2;
                size -= 1;
                if capacity > 8 && size < capacity * 3 / 8 {
                    let next_capacity = capacity / 2;
                    resize(&mut table, &mut capacity, next_capacity, &mut size);
                }
            } else {
                query_index += 1;
                query_sum += query_index * ((if found != capacity { 1 } else { 0 }) + VALUE_OFFSET);
            }
        } else if opcode == 4 {
            if key != 0 || value != 0 { return -1; }
            query_index += 1;
            query_sum += query_index * (size as i64 + VALUE_OFFSET);
        } else { return -1; }
    }

    let mut keys = [0i64; MAX_KEYS];
    let mut vals = [0i64; MAX_KEYS];
    let mut count = 0usize;
    for entry in table.iter().take(capacity).filter(|entry| entry.state == 1) {
        let mut at = count;
        count += 1;
        while at > 0 && keys[at - 1] > entry.key { keys[at] = keys[at - 1]; vals[at] = vals[at - 1]; at -= 1; }
        keys[at] = entry.key; vals[at] = entry.value;
    }
    let mut final_state = 0i64;
    for i in 0..count { final_state += (i as i64 + 1) * (keys[i] + 1) * (vals[i] + VALUE_OFFSET); }
    query_sum + final_state + size as i64
}
