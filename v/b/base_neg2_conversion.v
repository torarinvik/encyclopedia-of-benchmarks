module base_neg2_conversion

// Convert a signed 64-bit integer to canonical negabinary digits.
@[export: 'base_neg2_conversion']
pub fn base_neg2_conversion(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length != 1 { return -1 }
    original := unsafe { input[0] }
    mut width := usize(0)
    mut remaining := original
    for {
        mut quotient := remaining / -2
        mut digit := remaining % -2
        if digit < 0 { digit += 2; quotient++ }
        remaining = quotient
        width++
        if remaining == 0 { break }
    }
    if output_capacity < width { return -2 }
    mut top := usize(0)
    remaining = original
    for {
        mut quotient := remaining / -2
        mut digit := remaining % -2
        if digit < 0 { digit += 2; quotient++ }
        unsafe { output[top] = u8(`0`) + u8(digit) }
        top++
        remaining = quotient
        if remaining == 0 { break }
    }
    mut left := usize(0)
    mut right := top - 1
    for left < right {
        temporary := unsafe { output[left] }
        unsafe { output[left] = output[right] }
        unsafe { output[right] = temporary }
        left++; right--
    }
    return i64(top)
}
