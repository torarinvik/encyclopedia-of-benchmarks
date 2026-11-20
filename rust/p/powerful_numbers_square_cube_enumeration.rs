fn is_squarefree(value: i64) -> bool {
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % (divisor * divisor) == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn powerful_numbers_square_cube_enumeration(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || !(1..=2).contains(&length) || length != 1 {
        return -1;
    }
    let limit = *raw;
    if !(1..=100).contains(&limit) {
        return -1;
    }

    let mut values = [0_i64; 14];
    let mut count = 0_usize;
    let mut b = 1_i64;
    while b * b * b <= limit {
        if is_squarefree(b) {
            let cube = b * b * b;
            let mut a = 1_i64;
            while a * a * cube <= limit {
                values[count] = a * a * cube;
                count += 1;
                a += 1;
            }
        }
        b += 1;
    }
    for index in 1..count {
        let value = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > value {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }

    let output_bytes = (count + 1) * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let destination = std::slice::from_raw_parts_mut(output, output_bytes);
    store_i64_le(destination, 0, count as i64);
    for index in 0..count {
        store_i64_le(destination, (index + 1) * 8, values[index]);
    }
    output_bytes as i64
}
