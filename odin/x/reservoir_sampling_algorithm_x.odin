package reservoir_sampling_algorithm_x

import "core:c"

falling :: proc(top: i64, count: int) -> i64 {
    product: i64 = 1
    for i := 0; i < count; i += 1 { product *= top-i64(i) }
    return product
}

gcd_i64 :: proc(a_value, b_value: i64) -> i64 {
    a, b := a_value, b_value
    for b != 0 { remainder := a%b; a = b; b = remainder }
    return a
}

@(export)
reservoir_sampling_algorithm_x :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 49 || input[0] < 1 || input[0] > 16 { return -1 }
    if input[1] < 1 || input[1] > 8 { return -1 }
    n, k := int(input[0]), int(input[1])
    if (k & (k-1)) != 0 || k > n || int(length) != 2+n+2*(n-k) { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] < -1000000 || input[2+i] > 1000000 { return -1 } }
    for i := 2+n; i < int(length); i += 1 { if input[i] < 0 || input[i] > 4294967295 { return -1 } }
    if output == nil || capacity < c.size_t(8*k) { return -2 }
    sample: [8]i64
    for i := 0; i < k; i += 1 { sample[i] = input[2+i] }
    processed, attempt := k, 0
    for processed < n {
        draw, slot_draw := input[2+n+2*attempt], input[2+n+2*attempt+1]
        attempt += 1
        numerator := falling(i64(processed), k)
        denominator := falling(i64(processed+1), k)
        divisor := gcd_i64(numerator, denominator)
        numerator /= divisor
        denominator /= divisor
        max_skip := n-processed-1
        selected := 0
        found := false
        for skip := 0; skip <= max_skip; skip += 1 {
            if numerator*4294967297 <= (draw+1)*denominator { selected = skip; found = true; break }
            if skip < max_skip {
                top := i64(processed+skip+1)
                numerator *= top+1-i64(k)
                denominator *= top+1
                divisor = gcd_i64(numerator, denominator)
                numerator /= divisor
                denominator /= divisor
            }
        }
        if !found { break }
        slot := int(slot_draw % i64(k))
        sample[slot] = input[2+processed+selected]
        processed += selected+1
    }
    for i := 0; i < k; i += 1 {
        bits := transmute(u64)sample[i]
        for j := 0; j < 8; j += 1 { output[8*i+j] = u8(bits & 255); bits >>= 8 }
    }
    return i64(8*k)
}
