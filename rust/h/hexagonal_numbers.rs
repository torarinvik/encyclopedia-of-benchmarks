/// Emit the zero-based hexagonal number sequence as little-endian i64 values.
const MAX_LENGTH: i64 = 1024;
const BYTES_PER_VALUE: usize = 8;

unsafe fn store_i64_le(output: *mut u8, position: usize, value: i64) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() {
        *output.add(position + byte) = *octet;
    }
}

#[no_mangle]
pub extern "C" fn hexagonal_numbers(length: i64, output: *mut u8,
    output_capacity: usize) -> i64 {
    if !(1..=MAX_LENGTH).contains(&length) { return -1; }
    let n = length as usize;
    let required = n * BYTES_PER_VALUE;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..n {
        let i = index as i64;
        unsafe { store_i64_le(output, index * BYTES_PER_VALUE, i * (2 * i - 1)); }
    }
    length
}
