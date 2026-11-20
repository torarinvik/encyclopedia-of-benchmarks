package wieferich_prime_count_up_to_limit

import "core:c"

Max_Limit :: 5000
Max_Parseable_Length :: 2

modular_power :: proc "contextless" (base_value, exponent_value, modulus: i64) -> i64 {
    base, exponent := base_value, exponent_value
    result := i64(1)
    for exponent > 0 {
        if (exponent & 1) != 0 do result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    }
    return result
}

count_wieferich :: proc "contextless" (limit: int) -> i64 {
    prime: [Max_Limit + 1]u8 = {}
    for n := 0; n <= limit; n += 1 do prime[n] = 1
    prime[0] = 0
    prime[1] = 0
    for divisor := 2; divisor * divisor <= limit; divisor += 1 {
        if prime[divisor] == 0 do continue
        for multiple := divisor * divisor; multiple <= limit; multiple += divisor do prime[multiple] = 0
    }
    count := i64(0)
    for p := 3; p <= limit; p += 2 {
        if prime[p] != 0 && modular_power(2, i64(p - 1), i64(p) * i64(p)) == 1 do count += 1
    }
    return count
}

@(export)
wieferich_prime_count_up_to_limit :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(Max_Parseable_Length) do return -1
    if length != 1 || input[0] < 2 || input[0] > Max_Limit do return -1
    return count_wieferich(int(input[0]))
}
