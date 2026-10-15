module prime_factors

fn decimal_length(value i64) usize {
    mut remaining := value
    mut length := usize(1)
    for remaining >= 10 {
        remaining /= 10
        length++
    }
    return length
}

fn required_length(value i64) usize {
    mut length := usize(0)
    mut count := usize(0)
    mut remaining := value
    mut divisor := i64(2)
    for divisor <= remaining / divisor {
        for remaining % divisor == 0 {
            length += decimal_length(divisor)
            if count > 0 { length++ }
            count++
            remaining /= divisor
        }
        divisor++
    }
    if remaining > 1 {
        length += decimal_length(remaining)
        if count > 0 { length++ }
    }
    return length
}

fn append_decimal(value i64, output &u8, position_value usize) usize {
    mut digits := [10]u8{}
    mut count := 0
    mut remaining := value
    for remaining > 0 {
        digits[count] = u8(remaining % 10)
        count++
        remaining /= 10
    }
    mut position := position_value
    for count > 0 {
        count--
        unsafe { output[position] = u8(`0`) + digits[count] }
        position++
    }
    return position
}

// Encode prime factors in ascending order, retaining multiplicity.
@[export: 'prime_factors']
pub fn prime_factors(value i64, output &u8, output_capacity usize) i64 {
    if value < 1 || value > 2147483647 { return -1 }
    required := required_length(value)
    if output_capacity < required { return -2 }
    mut position := usize(0)
    mut count := usize(0)
    mut remaining := value
    mut divisor := i64(2)
    for divisor <= remaining / divisor {
        for remaining % divisor == 0 {
            if count > 0 {
                unsafe { output[position] = u8(`,`) }
                position++
            }
            position = append_decimal(divisor, output, position)
            count++
            remaining /= divisor
        }
        divisor++
    }
    if remaining > 1 {
        if count > 0 {
            unsafe { output[position] = u8(`,`) }
            position++
        }
        position = append_decimal(remaining, output, position)
    }
    return i64(position)
}
