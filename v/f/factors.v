module factors

fn decimal_length(value i64) usize {
    mut remaining := value
    mut length := usize(1)
    for remaining >= 10 {
        remaining /= 10
        length++
    }
    return length
}

fn append_decimal(value i64, output &u8, position_value usize) usize {
    mut digits := [3]u8{}
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

// List all positive divisors in ascending decimal order.
@[export: 'factors']
pub fn factors(value i64, output &u8, output_capacity usize) i64 {
    if value < 1 || value > 256 { return -1 }
    mut required := usize(0)
    mut count := usize(0)
    mut divisor := i64(1)
    for divisor <= value {
        if value % divisor == 0 {
            required += decimal_length(divisor)
            if count > 0 { required++ }
            count++
        }
        divisor++
    }
    if output_capacity < required { return -2 }
    mut position := usize(0)
    count = 0
    divisor = 1
    for divisor <= value {
        if value % divisor == 0 {
            if count > 0 {
                unsafe { output[position] = u8(`,`) }
                position++
            }
            position = append_decimal(divisor, output, position)
            count++
        }
        divisor++
    }
    return i64(position)
}
