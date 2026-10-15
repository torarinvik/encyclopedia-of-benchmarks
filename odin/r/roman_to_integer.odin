package roman_to_integer

import "core:c"

decode_roman_digit :: proc "contextless" (symbols: [^]i64, length, position: c.size_t,
    one, five, ten: i64) -> i64 {
    if position >= length do return 0
    if symbols[position] == one {
        if position + 1 < length && symbols[position + 1] == ten do return 146
        if position + 1 < length && symbols[position + 1] == five do return 66
        count := c.size_t(0)
        for position + count < length && symbols[position + count] == one && count < 3 { count += 1 }
        if position + count < length && symbols[position + count] == one do return -1
        return i64(count * 16 + count)
    }
    if symbols[position] == five {
        count := c.size_t(0)
        for position + 1 + count < length && symbols[position + 1 + count] == one && count < 3 { count += 1 }
        if position + 1 + count < length && symbols[position + 1 + count] == one do return -1
        return i64((5 + count) * 16 + 1 + count)
    }
    return 0
}

// Decode canonical uppercase Roman numerals in the range 1 through 3,999.
@(export)
roman_to_integer :: proc "c" (symbols: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 15 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        symbol := symbols[index]
        if symbol != 73 && symbol != 86 && symbol != 88 && symbol != 76 &&
           symbol != 67 && symbol != 68 && symbol != 77 { return -1 }
    }
    position := c.size_t(0)
    thousands := c.size_t(0)
    for position < length && symbols[position] == 77 && thousands < 3 {
        position += 1
        thousands += 1
    }
    if position < length && symbols[position] == 77 do return -1
    hundreds := decode_roman_digit(symbols, length, position, 67, 68, 77)
    if hundreds < 0 do return -1
    position += c.size_t(hundreds & 15)
    tens := decode_roman_digit(symbols, length, position, 88, 76, 67)
    if tens < 0 do return -1
    position += c.size_t(tens & 15)
    ones := decode_roman_digit(symbols, length, position, 73, 86, 88)
    if ones < 0 do return -1
    position += c.size_t(ones & 15)
    if position != length do return -1
    value := i64(thousands) * 1000 + (hundreds >> 4) * 100 + (tens >> 4) * 10 + (ones >> 4)
    if value < 1 || value > 3999 do return -1
    return value
}
