package miller_rabin_primality_checker

import "core:c"

next_word :: proc(state: ^u64) -> u64 {
    state^ += 0x9E3779B97F4A7C15
    z := state^
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB
    return z ^ (z >> 31)
}
mod_power :: proc(base_input, exponent_input, modulus: i64) -> i64 {
    base, exponent, result := base_input, exponent_input, i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 do result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    }
    return result
}
passes_witness :: proc(n, a, d, powers_of_two: i64) -> bool {
    x := mod_power(a, d, n)
    if x == 1 || x == n - 1 do return true
    for round := i64(1); round < powers_of_two; round += 1 {
        x = (x * x) % n
        if x == n - 1 do return true
    }
    return false
}

@(export)
miller_rabin_primality_checker :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || length > 4 do return -1
    n, rounds, seed := values[0], values[1], values[2]
    if length != 3 || n < 5 || n > 2_147_483_647 || (n & 1) == 0 || rounds < 1 || rounds > 64 || seed < 0 || seed > 2_147_483_647 do return -1
    state := u64(seed)
    span := u64(n - 4)
    threshold := (u64(0) - span) % span
    word: u64
    for {
        word = next_word(&state)
        if word >= threshold do break
    }
    a := 2 + i64(word % span)
    d, powers_of_two := n - 1, i64(0)
    for (d & 1) == 0 { d >>= 1; powers_of_two += 1 }
    for i := i64(0); i < rounds; i += 1 {
        if !passes_witness(n, a, d, powers_of_two) do return 0
    }
    return 1
}
