module decimal_to_any_base

// Convert a nonnegative signed 64-bit value to base 2 through 36.
@[export: 'decimal_to_any_base']
pub fn decimal_to_any_base(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length != 2 { return -1 }
    value := unsafe { input[0] }
    base := unsafe { input[1] }
    if value < 0 || base < 2 || base > 36 { return -1 }
    mut width := usize(1)
    mut remaining := value
    for remaining >= base {
        remaining /= base
        width++
    }
    if output_capacity < width { return -2 }
    mut position := width
    remaining = value
    for position > 0 {
        position--
        digit := remaining % base
        if digit < 10 {
            unsafe { output[position] = u8(`0`) + u8(digit) }
        } else {
            unsafe { output[position] = u8(`A`) + u8(digit - 10) }
        }
        remaining /= base
    }
    return i64(width)
}
