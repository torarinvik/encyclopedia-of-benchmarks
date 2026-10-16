module credit_card_validator

const max_text_length = 64

// Validate an ASCII card string using the source prefix and Luhn rules.
@[export: 'credit_card_validator']
pub fn credit_card_validator(input &i64, length usize) i64 {
    if length < 1 || length > max_text_length + 1 { return -1 }
    unsafe {
        n := input[0]
        if n < 0 || n > max_text_length || length != usize(n + 1) { return -1 }
        mut all_digits := true
        for i in 0 .. int(n) {
            ch := input[i + 1]
            if ch < 0 || ch > 127 { return -1 }
            if ch < 48 || ch > 57 { all_digits = false }
        }
        if !all_digits || n < 13 || n > 16 { return 0 }
        first, second := input[1] - 48, input[2] - 48
        if !(first == 4 || first == 5 || first == 6 || (first == 3 && (second == 4 || second == 5 || second == 7))) { return 0 }
        mut sum := 0
        for i in 0 .. int(n) {
            mut digit := int(input[i + 1] - 48)
            if i % 2 == int(n % 2) { digit *= 2; if digit > 9 { digit -= 9 } }
            sum += digit
        }
        if sum % 10 == 0 { return 1 }
        return 0
    }
}
