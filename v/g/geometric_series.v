module geometric_series
import math
fn put_f64_le(mut output &u8, offset int, value f64) {
    mut bits := math.bits_from_f64(value)
    for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}
@[export: 'geometric_series']
pub fn geometric_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length != 3 { return -1 }
    if input[0] < 0 || input[0] > 16 || input[1] < 1 || input[1] > 8 || input[2] < 1 || input[2] > 4 { return -1 }
    n := int(input[0]); if capacity < n * 8 || (n > 0 && unsafe { output == nil }) { return -2 }
    mut term := f64(input[1]); ratio := f64(input[2])
    for index in 0 .. n { put_f64_le(mut output, index * 8, term); term *= ratio }
    return i64(n * 8)
}
