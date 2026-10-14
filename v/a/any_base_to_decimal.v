module any_base_to_decimal

// Fold most-significant-first digits in base 2 through 36 into i64.
@[export: 'any_base_to_decimal']
pub fn any_base_to_decimal(input &i64, length usize) i64 {
    if length < 2 || length > 65 { return -1 }
    base := unsafe { input[0] }
    if base < 2 || base > 36 { return -1 }
    mut value := i64(0)
    for index := usize(1); index < length; index++ {
        digit := unsafe { input[index] }
        if digit < 0 || digit >= base { return -1 }
        if value > (9223372036854775807 - digit) / base { return -1 }
        value = value * base + digit
    }
    return value
}
