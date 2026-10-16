/// Emit the sorted unique pairwise sums of two bounded integer sets.
const MIN_SUM: i64 = -2000;
const SUM_COUNT: usize = 4001;
const MAX_SET_SIZE: i64 = 64;

fn decimal_width(mut value: i64) -> usize {
    let mut width = 1;
    if value < 0 { value = -value; width += 1; }
    while value >= 10 { value /= 10; width += 1; }
    width
}

fn append_signed_decimal(output: &mut [u8], mut position: usize, mut value: i64) -> usize {
    if value < 0 { output[position] = b'-'; position += 1; value = -value; }
    let mut digits = [0u8; 20];
    let mut count = 0;
    loop {
        digits[count] = (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        output[position] = b'0' + digits[count];
        position += 1;
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn sumset(values: *const i64, length: usize,
                                  output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let count_a = *values;
    let count_b = *values.add(1);
    if !(0..=MAX_SET_SIZE).contains(&count_a) || !(0..=MAX_SET_SIZE).contains(&count_b)
        || length != 2 + count_a as usize + count_b as usize { return -1; }
    let mut present = [false; SUM_COUNT];
    for index_a in 0..count_a as usize {
        let left = *values.add(index_a + 2);
        if !(-1000..=1000).contains(&left) { return -1; }
    }
    for index_b in 0..count_b as usize {
        let right = *values.add(count_a as usize + index_b + 2);
        if !(-1000..=1000).contains(&right) { return -1; }
    }
    for index_a in 0..count_a as usize {
        let left = *values.add(index_a + 2);
        for index_b in 0..count_b as usize {
            let right = *values.add(count_a as usize + index_b + 2);
            present[(left + right - MIN_SUM) as usize] = true;
        }
    }
    let mut needed = 0usize;
    for (index, exists) in present.iter().enumerate() {
        if *exists { needed += decimal_width(index as i64 + MIN_SUM) + 1; }
    }
    if needed == 0 { return 0; }
    if output.is_null() || output_capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_capacity);
    let mut position = 0;
    for (index, exists) in present.iter().enumerate() {
        if !exists { continue; }
        position = append_signed_decimal(out, position, index as i64 + MIN_SUM);
        out[position] = b'\n'; position += 1;
    }
    position as i64
}
