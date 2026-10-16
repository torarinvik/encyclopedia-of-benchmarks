package credit_card_validator

import "core:c"

MAX_TEXT_LENGTH :: 64

@(export)
credit_card_validator :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_TEXT_LENGTH + 1) do return -1
    n := input[0]
    if n < 0 || n > MAX_TEXT_LENGTH || length != c.size_t(n + 1) do return -1
    all_digits := true
    for i := 0; i < int(n); i += 1 {
        ch := input[i + 1]
        if ch < 0 || ch > 127 do return -1
        if ch < 48 || ch > 57 do all_digits = false
    }
    if !all_digits || n < 13 || n > 16 do return 0
    first, second := input[1] - 48, input[2] - 48
    if !(first == 4 || first == 5 || first == 6 || (first == 3 && (second == 4 || second == 5 || second == 7))) do return 0
    sum := 0
    for i := 0; i < int(n); i += 1 {
        digit := int(input[i + 1] - 48)
        if i % 2 == int(n % 2) { digit *= 2; if digit > 9 { digit -= 9 } }
        sum += digit
    }
    if sum % 10 == 0 { return 1 }
    return 0
}
