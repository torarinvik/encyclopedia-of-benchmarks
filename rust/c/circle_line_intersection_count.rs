const MAX_Q: usize = 32;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_Q;

fn write_i64(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn circle_line_intersection_count(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 101 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let center_x = values[0];
    let center_y = values[1];
    let radius = values[2];
    let query_value = values[3];
    if !(-1000..=1000).contains(&center_x)
        || !(-1000..=1000).contains(&center_y)
        || !(0..=1000).contains(&radius)
        || !(0..=MAX_Q as i64).contains(&query_value)
    {
        return -1;
    }
    let query_count = query_value as usize;
    if length != 4 + 3 * query_count {
        return -1;
    }
    let mut a_values = [0_i64; MAX_Q];
    let mut b_values = [0_i64; MAX_Q];
    let mut c_values = [0_i64; MAX_Q];
    for query in 0..query_count {
        let a = values[4 + 3 * query];
        let b = values[5 + 3 * query];
        let c = values[6 + 3 * query];
        if !(-100..=100).contains(&a)
            || !(-100..=100).contains(&b)
            || (a == 0 && b == 0)
            || !(-200_000..=200_000).contains(&c)
        {
            return -1;
        }
        a_values[query] = a;
        b_values[query] = b;
        c_values[query] = c;
    }
    let needed = 8 * query_count;
    if needed > 0 && (output.is_null() || capacity < needed) {
        return -2;
    }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    for query in 0..query_count {
        let a = a_values[query];
        let b = b_values[query];
        let offset = a * center_x + b * center_y + c_values[query];
        let normal_squared = a * a + b * b;
        let discriminant = radius * radius * normal_squared - offset * offset;
        let count = if discriminant > 0 { 2 } else if discriminant == 0 { 1 } else { 0 };
        write_i64(&mut staged, 8 * query, count);
    }
    for byte in 0..needed {
        *output.add(byte) = staged[byte];
    }
    needed as i64
}
