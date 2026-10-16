const MAX_VALUES: usize = 64;
const MODULUS: u64 = 2_147_483_647;

fn shuffle_recursive(values: &mut [i32; MAX_VALUES], item: isize, state: &mut u64) {
    if item <= 0 { return; }
    shuffle_recursive(values, item - 1, state);
    *state = (*state * 48_271) % MODULUS;
    let other = (*state % (item as u64 + 1)) as usize;
    values.swap(item as usize, other);
}

#[no_mangle]
pub unsafe extern "C" fn recursive_shuffler(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_VALUES + 1 { return -1; }
    let seed = *input;
    if !(1..MODULUS as i64).contains(&seed) { return -1; }
    let count = length - 1;
    let mut values = [0i32; MAX_VALUES];
    for index in 0..count {
        let value = *input.add(index + 1);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    let byte_count = count * 4;
    if output_capacity < byte_count || (byte_count != 0 && output.is_null()) { return -2; }
    let mut state = seed as u64;
    if count > 1 { shuffle_recursive(&mut values, count as isize - 1, &mut state); }
    for index in 0..count {
        let bits = values[index] as u32;
        for byte in 0..4 { *output.add(index * 4 + byte) = (bits >> (byte * 8)) as u8; }
    }
    count as i64
}
