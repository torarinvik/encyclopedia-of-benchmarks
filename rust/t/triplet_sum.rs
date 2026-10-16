fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

fn sort_three(values: &mut [i64; 3]) {
    if values[0] > values[1] { values.swap(0, 1); }
    if values[1] > values[2] { values.swap(1, 2); }
    if values[0] > values[1] { values.swap(0, 1); }
}

#[no_mangle]
pub unsafe extern "C" fn triplet_sum(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    const MAX_ITEMS: usize = 10;
    if input.is_null() || length < 1 || length > MAX_ITEMS + 1 {
        return -1;
    }
    let target = *input;
    if !(-3_000_000..=3_000_000).contains(&target) { return -1; }
    let item_count = length - 1;
    for index in 0..item_count {
        let value = *input.add(index + 1);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
    }
    if output_capacity < 24 || output.is_null() { return -2; }

    let mut result = [0i64; 3];
    'search: for first in 0..item_count {
        for second in 0..item_count {
            if second == first { continue; }
            for third in 0..item_count {
                if third == first || third == second { continue; }
                let a = *input.add(first + 1);
                let b = *input.add(second + 1);
                let c = *input.add(third + 1);
                if a + b + c == target {
                    result = [a, b, c];
                    sort_three(&mut result);
                    break 'search;
                }
            }
        }
    }
    for index in 0..3 { put_i64_le(output, index * 8, result[index]); }
    3
}
