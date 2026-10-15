module roman_to_integer

fn decode_roman_digit(symbols &i64, length usize, position usize, one i64, five i64, ten i64) i64 {
    if position >= length { return 0 }
    if unsafe { symbols[position] } == one {
        if position + 1 < length && unsafe { symbols[position + 1] } == ten { return 146 }
        if position + 1 < length && unsafe { symbols[position + 1] } == five { return 66 }
        mut count := usize(0)
        for position + count < length && unsafe { symbols[position + count] } == one && count < 3 { count++ }
        if position + count < length && unsafe { symbols[position + count] } == one { return -1 }
        return i64(count * 16 + count)
    }
    if unsafe { symbols[position] } == five {
        mut count := usize(0)
        for position + 1 + count < length && unsafe { symbols[position + 1 + count] } == one && count < 3 { count++ }
        if position + 1 + count < length && unsafe { symbols[position + 1 + count] } == one { return -1 }
        return i64((5 + count) * 16 + 1 + count)
    }
    return 0
}

// Decode canonical uppercase Roman numerals in the range 1 through 3,999.
@[export: 'roman_to_integer']
pub fn roman_to_integer(symbols &i64, length usize) i64 {
    if length == 0 || length > 15 { return -1 }
    for index in 0 .. length {
        symbol := unsafe { symbols[index] }
        if symbol != 73 && symbol != 86 && symbol != 88 && symbol != 76 &&
            symbol != 67 && symbol != 68 && symbol != 77 { return -1 }
    }
    mut position := usize(0)
    mut thousands := usize(0)
    for position < length && unsafe { symbols[position] } == 77 && thousands < 3 {
        position++
        thousands++
    }
    if position < length && unsafe { symbols[position] } == 77 { return -1 }
    hundreds := decode_roman_digit(symbols, length, position, 67, 68, 77)
    if hundreds < 0 { return -1 }
    position += usize(hundreds & 15)
    tens := decode_roman_digit(symbols, length, position, 88, 76, 67)
    if tens < 0 { return -1 }
    position += usize(tens & 15)
    ones := decode_roman_digit(symbols, length, position, 73, 86, 88)
    if ones < 0 { return -1 }
    position += usize(ones & 15)
    if position != length { return -1 }
    value := i64(thousands) * 1000 + (hundreds >> 4) * 100 + (tens >> 4) * 10 + (ones >> 4)
    if value < 1 || value > 3999 { return -1 }
    return value
}
