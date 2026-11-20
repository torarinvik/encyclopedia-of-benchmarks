const SET_LIMIT: usize = 8;
const KEY_LIMIT: i64 = 63;
const CELL_COUNT: usize = 48;
const MAX_PEELS: usize = 16;

fn checksum(key: i64) -> i64 { key * key + 3 * key + 7 }

fn location(key: i64, part: usize) -> usize {
    match part {
        0 => key as usize % 16,
        1 => 16 + ((3 * key as usize + 5) % 16),
        _ => 32 + ((5 * key as usize + 9) % 16),
    }
}

unsafe fn write_i64_le(output: *mut u8, word: usize, value: i64) {
    for (byte, part) in value.to_le_bytes().iter().enumerate() {
        output.add(word * 8 + byte).write(*part);
    }
}

#[no_mangle]
pub unsafe extern "C" fn invertible_bloom_lookup_table_reconciliation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=19).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let a_raw = values[0];
    let b_raw = values[1];
    if !(0..=SET_LIMIT as i64).contains(&a_raw) || !(0..=SET_LIMIT as i64).contains(&b_raw) { return -1; }
    let (a_count, b_count) = (a_raw as usize, b_raw as usize);
    if length != 2 + a_count + b_count { return -1; }
    for (start, count) in [(2usize, a_count), (2 + a_count, b_count)] {
        let mut previous = -1i64;
        for &key in &values[start..start + count] {
            if !(0..=KEY_LIMIT).contains(&key) || key <= previous { return -1; }
            previous = key;
        }
    }

    let mut counts = [0i64; CELL_COUNT];
    let mut sums = [0i64; CELL_COUNT];
    let mut checks = [0i64; CELL_COUNT];
    for (start, count, sign) in [(2usize, a_count, 1i64), (2 + a_count, b_count, -1i64)] {
        for &key in &values[start..start + count] {
            for part in 0..3 {
                let slot = location(key, part);
                counts[slot] += sign;
                sums[slot] += sign * key;
                checks[slot] += sign * checksum(key);
            }
        }
    }

    let mut positive = [0i64; MAX_PEELS];
    let mut negative = [0i64; MAX_PEELS];
    let (mut positive_count, mut negative_count) = (0usize, 0usize);
    let mut repeated = false;
    for _ in 0..MAX_PEELS {
        if (0..CELL_COUNT).all(|i| counts[i] == 0 && sums[i] == 0 && checks[i] == 0) { break; }
        let mut selected = None;
        for i in 0..CELL_COUNT {
            if counts[i] != 1 && counts[i] != -1 { continue; }
            let sign = counts[i];
            let key = sign * sums[i];
            if !(0..=KEY_LIMIT).contains(&key) || checks[i] != sign * checksum(key) { continue; }
            selected = Some((sign, key));
            break;
        }
        let Some((sign, key)) = selected else { break; };
        if positive[..positive_count].contains(&key) || negative[..negative_count].contains(&key) {
            repeated = true;
            break;
        }
        if sign > 0 { positive[positive_count] = key; positive_count += 1; }
        else { negative[negative_count] = key; negative_count += 1; }
        for part in 0..3 {
            let slot = location(key, part);
            counts[slot] -= sign;
            sums[slot] -= sign * key;
            checks[slot] -= sign * checksum(key);
        }
    }

    let zero = (0..CELL_COUNT).all(|i| counts[i] == 0 && sums[i] == 0 && checks[i] == 0);
    positive[..positive_count].sort_unstable();
    negative[..negative_count].sort_unstable();
    let mut staged = [0i64; 3 + 2 * MAX_PEELS];
    let mut words = 0usize;
    staged[words] = if !repeated && zero { 1 } else { 0 }; words += 1;
    staged[words] = positive_count as i64; words += 1;
    staged[words] = negative_count as i64; words += 1;
    for &key in &positive[..positive_count] { staged[words] = key; words += 1; }
    for &key in &negative[..negative_count] { staged[words] = key; words += 1; }
    let required = words * 8;
    if output.is_null() || capacity < required { return -2; }
    for i in 0..words { write_i64_le(output, i, staged[i]); }
    required as i64
}
