const BUCKETS: usize = 8;
const WIDTH: usize = 4;
const MAX_OPERATIONS: usize = 32;
const MAX_KICKS: usize = 8;

fn delta(fingerprint: i64) -> usize {
    1 + ((5 * fingerprint as usize + 3) % 7)
}

fn first_empty(table: &[i64; BUCKETS * WIDTH], bucket: usize) -> Option<usize> {
    (0..WIDTH).find(|&slot| table[bucket * WIDTH + slot] == 0)
}

fn insert(table: &mut [i64; BUCKETS * WIDTH], primary: usize, fingerprint: i64) -> bool {
    let alternate = primary ^ delta(fingerprint);
    if let Some(slot) = first_empty(table, primary) {
        table[primary * WIDTH + slot] = fingerprint;
        return true;
    }
    if let Some(slot) = first_empty(table, alternate) {
        table[alternate * WIDTH + slot] = fingerprint;
        return true;
    }

    let mut current = primary;
    let mut pending = fingerprint;
    for _ in 0..MAX_KICKS {
        let position = current * WIDTH;
        let evicted = table[position];
        table[position] = pending;
        pending = evicted;
        current ^= delta(pending);
        if let Some(slot) = first_empty(table, current) {
            table[current * WIDTH + slot] = pending;
            return true;
        }
    }
    false
}

unsafe fn write_i64_le(output: *mut u8, index: usize, value: i64) {
    for (offset, byte) in value.to_le_bytes().iter().enumerate() {
        output.add(index * 8 + offset).write(*byte);
    }
}

#[no_mangle]
pub unsafe extern "C" fn cuckoo_filter_operation_trace(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=98).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_count = values[0];
    if !(1..=MAX_OPERATIONS as i64).contains(&raw_count) { return -1; }
    let count = raw_count as usize;
    if length != 1 + 3 * count { return -1; }
    for operation in 0..count {
        let opcode = values[1 + 3 * operation];
        let primary = values[2 + 3 * operation];
        let fingerprint = values[3 + 3 * operation];
        if !(0..=2).contains(&opcode) || !(0..BUCKETS as i64).contains(&primary)
            || !(1..=15).contains(&fingerprint) { return -1; }
    }
    let required = count * 8;
    if output.is_null() || capacity < required { return -2; }

    let mut table = [0i64; BUCKETS * WIDTH];
    let mut statuses = [0i64; MAX_OPERATIONS];
    for operation in 0..count {
        let opcode = values[1 + 3 * operation];
        let primary = values[2 + 3 * operation] as usize;
        let fingerprint = values[3 + 3 * operation];
        let alternate = primary ^ delta(fingerprint);
        if opcode == 0 {
            if !insert(&mut table, primary, fingerprint) { return -3; }
            statuses[operation] = 1;
        } else if opcode == 1 {
            let mut found = false;
            for bucket in [primary, alternate] {
                for slot in 0..WIDTH {
                    if table[bucket * WIDTH + slot] == fingerprint { found = true; }
                }
            }
            statuses[operation] = if found { 1 } else { 0 };
        } else {
            let mut removed = false;
            for bucket in [primary, alternate] {
                for slot in 0..WIDTH {
                    let position = bucket * WIDTH + slot;
                    if table[position] == fingerprint {
                        table[position] = 0;
                        removed = true;
                        break;
                    }
                }
                if removed { break; }
            }
            statuses[operation] = if removed { 1 } else { 0 };
        }
    }
    for operation in 0..count { write_i64_le(output, operation, statuses[operation]); }
    required as i64
}
