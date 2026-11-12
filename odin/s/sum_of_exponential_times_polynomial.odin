package sum_of_exponential_times_polynomial

import "core:c"

MODULUS :: i64(998244353)
MAX_DEGREE :: 32

sepm_shift :: proc(source: []i64, shift: u64, degree: int, choose: []i64) -> [33]i64 {
    powers: [33]i64
    result: [33]i64
    powers[0] = 1
    reduced_shift := i64(shift % u64(MODULUS))
    for i := 1; i <= degree; i += 1 {
        powers[i] = powers[i - 1] * reduced_shift % MODULUS
    }
    for d := 0; d <= degree; d += 1 {
        total := i64(0)
        for k := 0; k <= d; k += 1 {
            term := choose[d * 33 + k] * powers[d - k] % MODULUS
            total = (total + term * source[k]) % MODULUS
        }
        result[d] = total
    }
    return result
}

sum_of_exponential_times_polynomial :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 3 do return -1
    r, degree_value, n_value := input[0], input[1], input[2]
    if r < 0 || r >= MODULUS || degree_value < 0 || degree_value > MAX_DEGREE ||
        n_value < 0 || n_value > 1000000000000000000 do return -1
    degree := int(degree_value)
    choose: [1089]i64
    choose[0] = 1
    for d := 1; d <= degree; d += 1 {
        choose[d * 33] = 1
        choose[d * 33 + d] = 1
        for k := 1; k < d; k += 1 {
            choose[d * 33 + k] = (choose[(d - 1) * 33 + k - 1] + choose[(d - 1) * 33 + k]) % MODULUS
        }
    }

    accumulated: [33]i64
    block: [33]i64
    block[0] = 1
    accumulated_power, block_power := i64(1), r
    accumulated_length, block_length := u64(0), u64(1)
    remaining := u64(n_value)
    for remaining > 0 {
        if remaining & 1 != 0 {
            shifted := sepm_shift(block[:], accumulated_length, degree, choose[:])
            for d := 0; d <= degree; d += 1 {
                accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % MODULUS
            }
            accumulated_power = accumulated_power * block_power % MODULUS
            accumulated_length += block_length
        }
        shifted_block := sepm_shift(block[:], block_length, degree, choose[:])
        for d := 0; d <= degree; d += 1 {
            block[d] = (block[d] + block_power * shifted_block[d]) % MODULUS
        }
        block_power = block_power * block_power % MODULUS
        block_length <<= 1
        remaining >>= 1
    }
    return accumulated[degree]
}
