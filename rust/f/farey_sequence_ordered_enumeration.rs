const MAX_ORDER: i64 = 32;

fn farey_count(order: i64) -> i64 {
    let (mut a, mut b, mut c, mut d) = (0i64, 1i64, 1i64, order);
    let mut count = 1i64;
    loop {
        count += 1;
        if c == d { break; }
        let k = (order + b) / d;
        let next_c = k * c - a;
        let next_d = k * d - b;
        (a, b, c, d) = (c, d, next_c, next_d);
    }
    count
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn farey_sequence_ordered_enumeration(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let order = unsafe { *input };
    if !(1..=MAX_ORDER).contains(&order) { return -1; }
    let count = farey_count(order);
    let required = ((1 + 2 * count) * 8) as usize;
    if output.is_null() || capacity < required { return -2; }

    store_i64_le(output, 0, count);
    store_i64_le(output, 8, 0);
    store_i64_le(output, 16, 1);
    let (mut a, mut b, mut c, mut d) = (0i64, 1i64, 1i64, order);
    let mut position = 24usize;
    loop {
        store_i64_le(output, position, c);
        store_i64_le(output, position + 8, d);
        position += 16;
        if c == d { break; }
        let k = (order + b) / d;
        let next_c = k * c - a;
        let next_d = k * d - b;
        (a, b, c, d) = (c, d, next_c, next_d);
    }
    required as i64
}
