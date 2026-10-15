/// Intersect three strictly increasing arrays and emit ascending signed i64 values.
const ARRAY_COUNT: usize = 3;
const MAX_ARRAY_LENGTH: usize = 64;
const BYTES_PER_VALUE: usize = 4;

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i64) {
    for (byte, octet) in (value as i32).to_le_bytes().iter().enumerate() {
        *output.add(position + byte) = *octet;
    }
}

#[no_mangle]
pub extern "C" fn sorted_arrays_intersection(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < ARRAY_COUNT || length > ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let mut starts = [0usize; ARRAY_COUNT];
    let mut sizes = [0usize; ARRAY_COUNT];
    let mut position = 0usize;
    for array in 0..ARRAY_COUNT {
        if position >= length || packed[position] < 0 || packed[position] > MAX_ARRAY_LENGTH as i64 { return -1; }
        let size = packed[position] as usize;
        position += 1;
        if size > length - position { return -1; }
        starts[array] = position;
        sizes[array] = size;
        for index in 0..size {
            if packed[position + index] < i32::MIN as i64 || packed[position + index] > i32::MAX as i64 { return -1; }
            if index > 0 && packed[position + index - 1] >= packed[position + index] { return -1; }
        }
        position += size;
    }
    if position != length { return -1; }
    let maximum_result = sizes[0].min(sizes[1]).min(sizes[2]);
    if output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result != 0 && output.is_null()) { return -2; }

    let mut cursor = [0usize; ARRAY_COUNT];
    let mut result_count = 0usize;
    while cursor[0] < sizes[0] && cursor[1] < sizes[1] && cursor[2] < sizes[2] {
        let first = packed[starts[0] + cursor[0]];
        let second = packed[starts[1] + cursor[1]];
        let third = packed[starts[2] + cursor[2]];
        if first == second && first == third {
            unsafe { store_i32_le(output, result_count * BYTES_PER_VALUE, first); }
            result_count += 1;
            cursor[0] += 1; cursor[1] += 1; cursor[2] += 1;
        } else if first < second {
            cursor[0] += 1;
        } else if second < third {
            cursor[1] += 1;
        } else {
            cursor[2] += 1;
        }
    }
    result_count as i64
}
