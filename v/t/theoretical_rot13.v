module theoretical_rot13

// Apply ROT13 only to lowercase non-NUL ASCII bytes.
@[export: 'theoretical_rot13']
pub fn theoretical_rot13(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 66 { return -1 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        if value < 1 || value > 127 { return -1 }
    }
    if output_capacity < length { return -2 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        mut mapped := value
        if value >= i64(`a`) && value <= i64(`z`) {
            mapped = i64(`a`) + (value - i64(`a`) + 13) % 26
        }
        unsafe { output[index] = u8(mapped) }
    }
    return i64(length)
}
