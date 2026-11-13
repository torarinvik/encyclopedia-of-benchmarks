package turnstile_one_sparse_fingerprint_recovery

import "core:c"

MODULUS :: i64(1000000007)

power_mod :: proc(base_value, exponent_value: i64) -> i64 {
    base := base_value
    exponent := exponent_value
    result: i64 = 1
    for exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS }
        base = base * base % MODULUS
        exponent >>= 1
    }
    return result
}

@(export)
turnstile_one_sparse_fingerprint_recovery :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 260 do return -1
    n := input[0]; q := input[1]; base := input[2]
    if n < 1 || n > 64 || q < 0 || q > 128 || base < 1 || base >= MODULUS do return -1
    if length != c.size_t(3 + 2 * q) do return -1
    mass: i64 = 0; weighted: i64 = 0; fingerprint: i64 = 0
    for i := 0; i < int(q); i += 1 {
        index := input[3 + 2 * i]; delta := input[4 + 2 * i]
        if index < 0 || index >= n || delta < -1000 || delta > 1000 do return -1
        mass += delta
        weighted += delta * index
        fingerprint = (fingerprint + delta * power_mod(base, index)) % MODULUS
        if fingerprint < 0 { fingerprint += MODULUS }
    }
    if mass == 0 || weighted % mass != 0 do return 0
    index := weighted / mass
    if index < 0 || index >= n do return 0
    expected := (mass * power_mod(base, index)) % MODULUS
    if expected < 0 { expected += MODULUS }
    if fingerprint == expected do return index + 1
    return 0
}
