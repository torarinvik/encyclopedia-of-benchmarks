const max_abs_component = i64(1_000_000)

fn fraction_magnitude(value i64) u64 {
    if value < 0 { return u64(-value) }
    return u64(value)
}

fn fraction_gcd(a u64, b u64) u64 {
    mut left := a
    mut right := b
    for right != 0 {
        remainder := left % right
        left = right
        right = remainder
    }
    return left
}

fn fraction_put_i64_le(mut output &u8, offset int, value i64) {
    unsafe {
        mut bits := u64(value)
        for byte in 0 .. 8 {
            output[offset + byte] = u8((bits >> (8 * byte)) & 255)
        }
    }
}

@[export: 'simplify_fraction']
pub fn simplify_fraction(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || input_length != 2 { return -1 }
        numerator, denominator := input[0], input[1]
        if numerator < -max_abs_component || numerator > max_abs_component ||
            denominator < -max_abs_component || denominator > max_abs_component || denominator == 0 { return -1 }
        divisor := i64(fraction_gcd(fraction_magnitude(numerator), fraction_magnitude(denominator)))
        reduced_numerator, reduced_denominator := numerator / divisor, denominator / divisor
        mut staged := [16]u8{}
        fraction_put_i64_le(mut staged[0], 0, reduced_numerator)
        fraction_put_i64_le(mut staged[0], 8, reduced_denominator)
        if output == nil || capacity < 16 { return -2 }
        for i in 0 .. 16 { output[i] = staged[i] }
        return 16
    }
}
