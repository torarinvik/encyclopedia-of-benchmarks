const MAX_INPUT_LENGTH: usize = 513;
const MAX_LENGTH: usize = 256;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn shuffle(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let count = match exact_integer(values[0], 0, MAX_LENGTH as i64) { Some(value) => value as usize, None => return -1 };
    let offset_count = count.saturating_sub(1);
    if input_length != 1 + count + offset_count { return -1; }

    let mut items = [0_i32; MAX_LENGTH];
    for index in 0..count {
        let value = match exact_integer(values[1 + index], i32::MIN as i64, i32::MAX as i64) {
            Some(value) => value,
            None => return -1,
        };
        items[index] = value as i32;
    }
    let mut offsets = [0_usize; MAX_LENGTH];
    for index in 0..offset_count {
        let offset = match exact_integer(values[1 + count + index], 0, (count - 1 - index) as i64) {
            Some(value) => value as usize,
            None => return -1,
        };
        offsets[index] = offset;
    }
    for index in 0..offset_count {
        items.swap(index, index + offsets[index]);
    }

    if output.is_null() || output_capacity < count { return -2; }
    for index in 0..count { *output.add(index) = items[index] as f64; }
    count as i64
}
