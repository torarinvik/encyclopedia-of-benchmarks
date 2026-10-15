package is_spain_national_id

import "core:c"

CHECK_LETTERS :: "TRWAGMYFPDXBNJZSQVHLCKE"

@(export)
is_spain_national_id :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || (length != 9 && length != 10) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < 0 || input[index] > 127 do return -1
    }
    if length == 10 && input[8] != 45 do return -1
    number: i64 = 0
    for index := 0; index < 8; index += 1 {
        if input[index] < 48 || input[index] > 57 do return -1
        number = number * 10 + input[index] - 48
    }
    letter := input[int(length) - 1]
    if letter >= 97 && letter <= 122 do letter -= 32
    if letter < 65 || letter > 90 do return -1
    if letter == i64(CHECK_LETTERS[int(number % 23)]) do return 1
    return 0
}
