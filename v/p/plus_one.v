module plus_one

// Increment decimal digits and write their ASCII representation.
@[export: 'plus_one']
pub fn plus_one(digits &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 256 { return -1 }
    unsafe {
        mut all_nines := true
        for index in 0 .. length {
            digit := digits[index]
            if digit < 0 || digit > 9 { return -1 }
            if digit != 9 { all_nines = false }
        }
        if length > 1 && digits[0] == 0 { return -1 }
        output_length := if length == 0 || all_nines { length + 1 } else { length }
        if output_capacity < output_length { return -2 }
        if length == 0 || all_nines {
            output[0] = u8(`1`)
            for index in 1 .. output_length { output[index] = u8(`0`) }
            return i64(output_length)
        }
        for index in 0 .. length { output[index] = u8(`0` + digits[index]) }
        for index := int(length) - 1; index >= 0; index-- {
            if digits[index] == 9 { output[index] = u8(`0`) }
            else {
                output[index]++
                break
            }
        }
        return i64(output_length)
    }
}
