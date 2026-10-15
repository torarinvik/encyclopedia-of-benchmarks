module integer_to_roman

fn roman_digit_length(digit i64) usize {
    if digit == 4 || digit == 9 { return 2 }
    if digit >= 5 { return usize(digit - 4) }
    return usize(digit)
}

fn append_roman_digit(digit_value i64, one u8, five u8, ten u8, output &u8, position_value usize) usize {
    mut digit := digit_value
    mut position := position_value
    if digit == 9 {
        unsafe { output[position] = one; output[position + 1] = ten }
        return position + 2
    }
    if digit >= 5 {
        unsafe { output[position] = five }
        position++
        digit -= 5
    }
    if digit == 4 {
        unsafe { output[position] = one; output[position + 1] = five }
        return position + 2
    }
    for digit > 0 {
        unsafe { output[position] = one }
        position++
        digit--
    }
    return position
}

// Encode an integer in canonical uppercase Roman numerals.
@[export: 'integer_to_roman']
pub fn integer_to_roman(value i64, output &u8, output_capacity usize) i64 {
    if value < 1 || value > 3999 { return -1 }
    width := usize(value / 1000) + roman_digit_length((value / 100) % 10) +
        roman_digit_length((value / 10) % 10) + roman_digit_length(value % 10)
    if output_capacity < width { return -2 }
    mut position := usize(0)
    for _ in 0 .. int(value / 1000) {
        unsafe { output[position] = u8(77) }
        position++
    }
    position = append_roman_digit((value / 100) % 10, u8(67), u8(68), u8(77), output, position)
    position = append_roman_digit((value / 10) % 10, u8(88), u8(76), u8(67), output, position)
    position = append_roman_digit(value % 10, u8(73), u8(86), u8(88), output, position)
    return i64(position)
}
