package problem119

digit_sum :: proc(value_in: i64) -> i64 {
    value := value_in
    sum := i64(0)
    for value > 0 { sum += value % 10; value /= 10 }
    return sum
}

@(export)
problem119 :: proc "c" (index: i64) -> i64 {
    if index < 1 || index > 30 do return -1
    values: [10000]i64
    count := 0
    for base := i64(2); base < 100; base += 1 {
        value := base * base
        for exponent := 2; exponent < 100; exponent += 1 {
            if digit_sum(value) == base { values[count] = value; count += 1 }
            if value > 9223372036854775807 / base do break
            value *= base
        }
    }
    for i := 1; i < count; i += 1 {
        value := values[i]
        j := i
        for j > 0 && values[j - 1] > value { values[j] = values[j - 1]; j -= 1 }
        values[j] = value
    }
    return values[index - 1]
}
