package is_polish_national_id

import "core:c"

@(export)
is_polish_national_id :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 11 do return -1
    number: i64 = 0
    for index := 0; index < 11; index += 1 {
        if input[index] < 48 || input[index] > 57 do return -1
        number = number * 10 + input[index] - 48
    }
    if number < 10100000 || number > 99923199999 do return 0
    month := (input[2] - 48) * 10 + input[3] - 48
    valid_month := (month >= 1 && month <= 12) || (month >= 21 && month <= 32) ||
        (month >= 41 && month <= 52) || (month >= 61 && month <= 72) || (month >= 81 && month <= 92)
    if !valid_month do return 0
    day := (input[4] - 48) * 10 + input[5] - 48
    if day < 1 || day > 31 do return 0
    weights := [4]i64{1, 3, 7, 9}
    subtotal: i64 = 0
    for index := 0; index < 10; index += 1 {
        subtotal += ((input[index] - 48) * weights[index % 4]) % 10
    }
    checksum := 10 - subtotal % 10
    if checksum == number % 10 do return 1
    return 0
}
