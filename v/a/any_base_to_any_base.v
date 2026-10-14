module any_base_to_any_base

// Convert radix digits through checked decimal accumulation.
@[export: 'any_base_to_any_base']
pub fn any_base_to_any_base(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 3 || length > 65 { return -1 }
    source_base := unsafe { input[0] }
    target_base := unsafe { input[1] }
    if source_base < 2 || source_base > 36 || target_base < 2 || target_base > 36 { return -1 }
    mut value := i64(0)
    for index := usize(2); index < length; index++ {
        digit := unsafe { input[index] }
        if digit < 0 || digit >= source_base { return -1 }
        if value > (9223372036854775807 - digit) / source_base { return -1 }
        value = value * source_base + digit
    }
    mut width := usize(1)
    mut remaining := value
    for remaining >= target_base { remaining /= target_base; width++ }
    if output_capacity < width { return -2 }
    mut top := usize(0)
    remaining = value
    if remaining == 0 { unsafe { output[top] = u8(`0`) }; top++ }
    for remaining > 0 {
        digit := remaining % target_base
        if digit < 10 { unsafe { output[top] = u8(`0`) + u8(digit) } }
        else { unsafe { output[top] = u8(`A`) + u8(digit - 10) } }
        top++
        remaining /= target_base
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
