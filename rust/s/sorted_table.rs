const MAX_INITIAL_KEYS: usize = 128;
const MAX_OPERATIONS: usize = 256;
const MAX_SIZE: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 899;
const MIN_KEY: i64 = -1_000_000;
const MAX_KEY: i64 = 1_000_000;
const HASH_MODULUS: i64 = 1_000_000_007;

fn lower_bound(items: &[i64; MAX_SIZE], count: usize, key: i64) -> usize {
    let mut left = 0;
    let mut right = count;
    while left < right {
        let middle = left + (right - left) / 2;
        if items[middle] < key { left = middle + 1; } else { right = middle; }
    }
    left
}

fn upper_bound(items: &[i64; MAX_SIZE], count: usize, key: i64) -> usize {
    let mut left = 0;
    let mut right = count;
    while left < right {
        let middle = left + (right - left) / 2;
        if items[middle] <= key { left = middle + 1; } else { right = middle; }
    }
    left
}

fn key_code(key: i64) -> i64 { key - MIN_KEY + 1 }

fn sequence_code(items: &[i64; MAX_SIZE], start: usize, end: usize, descending: bool) -> i64 {
    let mut hash = 0_i64;
    if descending {
        for index in (start..end).rev() { hash = (31 * hash + key_code(items[index])) % HASH_MODULUS; }
    } else {
        for index in start..end { hash = (31 * hash + key_code(items[index])) % HASH_MODULUS; }
    }
    ((end - start) as i64) * HASH_MODULUS + hash
}

#[no_mangle]
pub unsafe extern "C" fn sorted_table_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_INITIAL_KEYS as i64 { return -1; }
    let initial_count = values[0] as usize;
    let operation_count_index = initial_count + 1;
    if operation_count_index >= length { return -1; }
    let operation_count_value = values[operation_count_index];
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = operation_count_value as usize;
    if length != operation_count_index + 1 + 3 * operation_count || length > 898 { return -1; }

    let mut items = [0_i64; MAX_SIZE];
    let mut count = initial_count;
    for index in 0..initial_count {
        let key = values[index + 1];
        if !(MIN_KEY..=MAX_KEY).contains(&key) || (index > 0 && items[index - 1] >= key) { return -1; }
        items[index] = key;
    }

    let mut checksum = 0_i128;
    let operations_start = operation_count_index + 1;
    for operation in 0..operation_count {
        let position = operations_start + operation * 3;
        let opcode = values[position];
        let first = values[position + 1];
        let second = values[position + 2];
        let observed: Option<i64>;
        match opcode {
            0 | 1 | 4 | 5 | 7 => {
                if second != 0 || !(MIN_KEY..=MAX_KEY).contains(&first) { return -1; }
                let at = lower_bound(&items, count, first);
                let found = at < count && items[at] == first;
                observed = match opcode {
                    0 => Some(if found { key_code(first) } else { 0 }),
                    1 => Some(if found { 1 } else { 0 }),
                    4 => { let next = if found { at + 1 } else { at }; Some(if next < count { key_code(items[next]) } else { 0 }) },
                    5 => { let previous = if found { at } else { at }; Some(if previous > 0 { key_code(items[previous - 1]) } else { 0 }) },
                    _ => {
                        if found {
                            for index in at..count - 1 { items[index] = items[index + 1]; }
                            count -= 1;
                            Some(key_code(first))
                        } else { Some(0) }
                    }
                };
            }
            2 | 3 => {
                if first != 0 || second != 0 { return -1; }
                observed = if count == 0 { Some(0) } else if opcode == 2 { Some(key_code(items[0])) } else { Some(key_code(items[count - 1])) };
            }
            6 => {
                if !(MIN_KEY..=MAX_KEY).contains(&first) || (second != 0 && second != 1) { return -1; }
                let at = lower_bound(&items, count, first);
                if at < count && items[at] == first { observed = Some(key_code(items[at])); }
                else {
                    if count >= MAX_SIZE { return -1; }
                    for index in (at..count).rev() { items[index + 1] = items[index]; }
                    items[at] = first;
                    count += 1;
                    observed = Some(0);
                }
            }
            8 | 9 => {
                if !(MIN_KEY..=MAX_KEY).contains(&first) || !(MIN_KEY..=MAX_KEY).contains(&second) { return -1; }
                let (start, end) = if first > second { (0, 0) } else { (lower_bound(&items, count, first), upper_bound(&items, count, second)) };
                observed = Some(sequence_code(&items, start, end, opcode == 9));
            }
            10 | 11 => {
                if first != 0 || second != 0 { return -1; }
                observed = Some(sequence_code(&items, 0, count, opcode == 11));
            }
            12 => {
                if first != 0 || second != 0 { return -1; }
                observed = Some(if count == 0 { 1 } else { 0 });
            }
            13 => {
                if first != 0 || second != 0 { return -1; }
                count = 0;
                observed = None;
            }
            _ => return -1,
        }
        if let Some(result) = observed { checksum += (operation as i128 + 1) * (result as i128 + 1); }
    }
    for index in 0..count { checksum += (operation_count as i128 + index as i128 + 1) * key_code(items[index]) as i128; }
    checksum as i64
}
