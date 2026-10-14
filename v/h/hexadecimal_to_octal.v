module hexadecimal_to_octal

// Convert a most-significant-first hexadecimal digit array to radix 8 text.
@[export: 'hexadecimal_to_octal']
pub fn hexadecimal_to_octal(digits &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > 16 { return -1 }
    if length == 16 && unsafe { digits[0] } > 7 { return -1 }
    mut value := i64(0)
    for index in 0 .. length {
        hex_digit := unsafe { digits[index] }
        if hex_digit < 0 || hex_digit > 15 { return -1 }
        value = value * 16 + hex_digit
    }
    mut width := usize(1)
    mut remaining := value
    for remaining >= 8 {
        remaining /= 8
        width++
    }
    if output_capacity < width { return -2 }
    mut position := width
    remaining = value
    for position > 0 {
        position--
        digit := remaining % 8
        if digit < 10 {
            unsafe { output[position] = u8(`0`) + u8(digit) }
        } else {
            unsafe { output[position] = u8(`a`) + u8(digit - 10) }
        }
        remaining /= 8
    }
    return i64(width)
}
