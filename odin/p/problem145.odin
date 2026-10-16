package problem145

count_reversible :: proc "contextless" (remaining, carry_in: i64, digits: ^[9]int, length: i64) -> i64 {
    if remaining == 0 {
        if digits[0] == 0 || digits[length - 1] == 0 do return 0
        carry := carry_in
        for i := length / 2 - 1; i >= 0; i -= 1 {
            carry += i64(digits[i] + digits[length - i - 1])
            if carry % 2 == 0 do return 0
            carry /= 10
        }
        return 1
    }
    if remaining == 1 {
        if carry_in % 2 == 0 do return 0
        result := i64(0)
        for digit := 0; digit < 10; digit += 1 {
            digits[length / 2] = digit
            result += count_reversible(0, (carry_in + 2 * i64(digit)) / 10, digits, length)
        }
        return result
    }
    result := i64(0)
    right_index := (length + remaining) / 2 - 1
    left_index := (length - remaining) / 2
    for digit1 := 0; digit1 < 10; digit1 += 1 {
        digits[right_index] = digit1
        parity := 0
        if (carry_in + i64(digit1)) % 2 == 0 { parity = 1 }
        for digit2 := parity; digit2 < 10; digit2 += 2 {
            digits[left_index] = digit2
            result += count_reversible(remaining - 2, (carry_in + i64(digit1 + digit2)) / 10, digits, length)
        }
    }
    return result
}

@(export)
problem145 :: proc "c" (max_power: i64) -> i64 {
    if max_power > 9 do return -1
    if max_power <= 0 do return 0
    digits: [9]int
    total := i64(0)
    for length := i64(1); length <= max_power; length += 1 {
        if (length - 1) % 4 != 0 do total += count_reversible(length, 0, &digits, length)
    }
    return total
}
