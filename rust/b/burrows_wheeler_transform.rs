/// Case-sensitive Burrows-Wheeler transform over packed ASCII bytes.
const MAX_LENGTH: usize = 256;

unsafe fn rotation_less(values: *const i64, n: usize, left: usize, right: usize) -> bool {
    for offset in 0..n {
        let a = *values.add(1 + (left + offset) % n);
        let b = *values.add(1 + (right + offset) % n);
        if a != b { return a < b; }
    }
    left < right
}

#[no_mangle]
pub unsafe extern "C" fn burrows_wheeler_transform(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let length_value = *values;
    if !(1..=MAX_LENGTH as i64).contains(&length_value) { return -1; }
    let n = length_value as usize;
    if length != n + 1 { return -1; }
    for i in 1..length { if !(0..=127).contains(&*values.add(i)) { return -1; } }
    let output_length = n + 4;
    if output_capacity < output_length || output.is_null() { return -2; }

    let mut order = [0usize; MAX_LENGTH];
    for i in 0..n { order[i] = i; }
    for i in 1..n {
        let key = order[i];
        let mut position = i;
        while position > 0 && rotation_less(values, n, key, order[position - 1]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    let mut primary_index = 0;
    for row in 0..n { if order[row] == 0 { primary_index = row; } }
    let encoded_index = primary_index as u32;
    for byte in 0..4 { *output.add(byte) = (encoded_index >> (8 * byte)) as u8; }
    for row in 0..n {
        *output.add(4 + row) = *values.add(1 + (order[row] + n - 1) % n) as u8;
    }
    output_length as i64
}
