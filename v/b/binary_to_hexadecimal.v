module binary_to_hexadecimal

// Convert a most-significant-first bit array to radix 16 text.
@[export: 'binary_to_hexadecimal']
pub fn binary_to_hexadecimal(bits &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > 63 { return -1 }
    mut value := i64(0)
    for index in 0 .. length {
        bit := unsafe { bits[index] }
        if bit < 0 || bit > 1 { return -1 }
        value = value * 2 + bit
    }
    mut width := usize(1)
    mut remaining := value
    for remaining >= 16 {
        remaining /= 16
        width++
    }
    if output_capacity < width { return -2 }
    mut position := width
    remaining = value
    for position > 0 {
        position--
        digit := remaining % 16
        if digit < 10 {
            unsafe { output[position] = u8(`0`) + u8(digit) }
        } else {
            unsafe { output[position] = u8(`a`) + u8(digit - 10) }
        }
        remaining /= 16
    }
    return i64(width)
}
