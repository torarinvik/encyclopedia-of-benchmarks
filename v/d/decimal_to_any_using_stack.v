module decimal_to_any_using_stack

// Convert a nonnegative signed 64-bit value with a LIFO digit stack.
@[export: 'decimal_to_any_using_stack']
pub fn decimal_to_any_using_stack(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length != 2 { return -1 }
    value := unsafe { input[0] }
    base := unsafe { input[1] }
    if value < 0 || base < 2 || base > 16 { return -1 }
    mut width := usize(1)
    mut remaining := value
    for remaining >= base { remaining /= base; width++ }
    if output_capacity < width { return -2 }
    mut top := usize(0)
    remaining = value
    if remaining == 0 { unsafe { output[top] = u8(`0`) }; top++ }
    for remaining > 0 {
        digit := remaining % base
        if digit < 10 {
            unsafe { output[top] = u8(`0`) + u8(digit) }
        } else {
            unsafe { output[top] = u8(`A`) + u8(digit - 10) }
        }
        top++
        remaining /= base
    }
    mut left := usize(0)
    mut right := top - 1
    for left < right {
        temporary := unsafe { output[left] }
        unsafe { output[left] = output[right] }
        unsafe { output[right] = temporary }
        left++
        right--
    }
    return i64(top)
}
