const INVALID_RESULT: i64 = i64::MIN;
const MAX_ITEMS: usize = 512;
const TABLE_SIZE: usize = 2048;

fn slot_for(value: i64) -> usize {
    let magnitude = if value < 0 { -value } else { value };
    (magnitude % TABLE_SIZE as i64) as usize
}

#[no_mangle]
pub unsafe extern "C" fn subarray_sum_equals_k(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_ITEMS + 2 {
        return INVALID_RESULT;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    let target = values[1];
    if count_value < 0 || count_value > MAX_ITEMS as i64 ||
        target < i32::MIN as i64 || target > i32::MAX as i64 {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    if length != count + 2 {
        return INVALID_RESULT;
    }
    if values[2..].iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return INVALID_RESULT;
    }

    let mut keys = [0_i64; TABLE_SIZE];
    let mut frequencies = [0_i64; TABLE_SIZE];
    frequencies[0] = 1;
    let mut prefix_sum = 0_i64;
    let mut result = 0_i64;
    for &value in &values[2..] {
        prefix_sum += value;
        let required = prefix_sum - target;
        let mut slot = slot_for(required);
        while frequencies[slot] != 0 && keys[slot] != required {
            slot = (slot + 1) % TABLE_SIZE;
        }
        result += frequencies[slot];

        slot = slot_for(prefix_sum);
        while frequencies[slot] != 0 && keys[slot] != prefix_sum {
            slot = (slot + 1) % TABLE_SIZE;
        }
        if frequencies[slot] == 0 {
            keys[slot] = prefix_sum;
        }
        frequencies[slot] += 1;
    }
    result
}
