/// Reverse a DNA sequence and complement each base.
const MAX_REVERSE_COMPLEMENT_LENGTH: usize = 1000;

#[no_mangle]
pub unsafe extern "C" fn reverse_complement(input: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_REVERSE_COMPLEMENT_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for i in 0..length {
        let base = *input.add(i);
        if base != b'A' as i64 && base != b'C' as i64 && base != b'G' as i64 && base != b'T' as i64 { return -1; }
    }
    if output_capacity < length || (length != 0 && output.is_null()) { return -2; }
    for i in 0..length {
        let base = *input.add(length - 1 - i);
        *output.add(i) = if base == b'A' as i64 { b'T' }
                         else if base == b'T' as i64 { b'A' }
                         else if base == b'C' as i64 { b'G' }
                         else { b'C' };
    }
    length as i64
}
