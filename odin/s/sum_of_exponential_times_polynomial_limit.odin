package sum_of_exponential_times_polynomial_limit

import "core:c"

MODULUS :: i64(998244353)
MAX_DEGREE :: 256

seppl_mod_pow :: proc "contextless" (base_input: i64, exponent_input: i64) -> i64 {
    base, exponent, result := base_input, exponent_input, i64(1)
    for exponent > 0 {
        if exponent % 2 == 1 do result = result * base % MODULUS
        base = base * base % MODULUS
        exponent /= 2
    }
    return result
}

seppl_evaluate :: proc "contextless" (input: [2]i64) -> i64 {
    r, degree_value := input[0], input[1]
    if r < 0 || r >= MODULUS || r == 1 || degree_value < 0 || degree_value > MAX_DEGREE do return -1
    degree := int(degree_value)
    denominator := (1 - r + MODULUS) % MODULUS
    inverse := seppl_mod_pow(denominator, MODULUS - 2)
    if degree == 0 do return inverse

    row: [MAX_DEGREE + 1]i64
    next_row: [MAX_DEGREE + 1]i64
    row[0] = 1
    for n := 1; n <= degree; n += 1 {
        for k := 0; k <= n; k += 1 {
            value := i64(0)
            if k > 0 do value += i64(n - k) * row[k - 1]
            if k < n do value += i64(k + 1) * row[k]
            next_row[k] = value % MODULUS
        }
        for k := 0; k <= n; k += 1 {
            row[k] = next_row[k]
            next_row[k] = 0
        }
    }

    eulerian_value := i64(0)
    for k := degree; k > 0; k -= 1 {
        eulerian_value = (eulerian_value * r + row[k - 1]) % MODULUS
    }
    denominator_power := seppl_mod_pow(inverse, i64(degree + 1))
    return r * eulerian_value % MODULUS * denominator_power % MODULUS
}

@(export)
sum_of_exponential_times_polynomial_limit :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    values: [2]i64
    values[0] = input[0]
    values[1] = input[1]
    return seppl_evaluate(values)
}
