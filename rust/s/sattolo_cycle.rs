const MAX_VALUES: usize = 1024;
const MODULUS: u64 = 2_147_483_647;

/// Deterministic Sattolo cycle shuffle using a portable Park–Miller stream.
#[no_mangle]
pub unsafe extern "C" fn sattolo_cycle(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_VALUES + 1 { return -1; }
    let seed = *input;
    if !(1..MODULUS as i64).contains(&seed) { return -1; }
    let count = length - 1;
    let byte_count = count * 4;
    let mut values = [0i32; MAX_VALUES];
    for index in 0..count {
        let value = *input.add(index + 1);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    if output_capacity < byte_count || (byte_count != 0 && output.is_null()) { return -2; }
    let mut state = seed as u64;
    let mut remaining = count;
    while remaining > 1 {
        state = (state * 48_271) % MODULUS;
        let other = (state % (remaining - 1) as u64) as usize;
        values.swap(remaining - 1, other);
        remaining -= 1;
    }
    for (index, value) in values[..count].iter().enumerate() {
        for byte in 0..4 {
            *output.add(index * 4 + byte) = ((*value as u32) >> (byte * 8)) as u8;
        }
    }
    count as i64
}
