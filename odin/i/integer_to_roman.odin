package integer_to_roman

import "core:c"

roman_digit_length :: proc "contextless" (digit: i64) -> c.size_t {
    if digit == 4 || digit == 9 do return 2
    if digit >= 5 do return c.size_t(digit - 4)
    return c.size_t(digit)
}

append_roman_digit :: proc "contextless" (digit_value: i64, one, five, ten: u8,
    output: [^]u8, position_value: c.size_t) -> c.size_t {
    digit := digit_value
    position := position_value
    if digit == 9 {
        output[position] = one
        output[position + 1] = ten
        return position + 2
    }
    if digit >= 5 {
        output[position] = five
        position += 1
        digit -= 5
    }
    if digit == 4 {
        output[position] = one
        output[position + 1] = five
        return position + 2
    }
    for digit > 0 {
        output[position] = one
        position += 1
        digit -= 1
    }
    return position
}

// Encode an integer in canonical uppercase Roman numerals.
@(export)
integer_to_roman :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if value < 1 || value > 3999 do return -1
    width := c.size_t(value / 1000) + roman_digit_length((value / 100) % 10) +
        roman_digit_length((value / 10) % 10) + roman_digit_length(value % 10)
    if output == nil || output_capacity < width do return -2
    position := c.size_t(0)
    for thousands := value / 1000; thousands > 0; thousands -= 1 {
        output[position] = u8('M')
        position += 1
    }
    position = append_roman_digit((value / 100) % 10, u8('C'), u8('D'), u8('M'), output, position)
    position = append_roman_digit((value / 10) % 10, u8('X'), u8('L'), u8('C'), output, position)
    position = append_roman_digit(value % 10, u8('I'), u8('V'), u8('X'), output, position)
    return i64(position)
}
