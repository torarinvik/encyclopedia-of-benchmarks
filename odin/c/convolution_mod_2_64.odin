package convolution_mod_2_64

import "core:c"

MAX_LENGTH :: 64
MAX_NTT_SIZE :: 128
MAX_INPUT_LENGTH :: 2 + 2*MAX_LENGTH + 1
MAX_RESULT_LENGTH :: 2*MAX_LENGTH - 1
P0 :: i64(998244353)
P1 :: i64(985661441)
P2 :: i64(943718401)
P3 :: i64(935329793)
P4 :: i64(918552577)

power_mod :: proc "contextless" (base_value, exponent_value, modulus: i64) -> i64 {
    base, exponent := base_value, exponent_value
    result := i64(1)
    for exponent > 0 {
        if (exponent & 1) != 0 { result = (result * base) % modulus }
        base = (base * base) % modulus
        exponent >>= 1
    }
    return result
}

transform :: proc "contextless" (values: ^[MAX_NTT_SIZE]i64, n: int,
    modulus, primitive_root: i64, inverse: bool) {
    j := 0
    for i := 1; i < n; i += 1 {
        bit := n >> 1
        for (j & bit) != 0 { j ^= bit; bit >>= 1 }
        j ^= bit
        if i < j { values[i], values[j] = values[j], values[i] }
    }
    for stage := 2; stage <= n; stage <<= 1 {
        root := power_mod(primitive_root, (modulus - 1) / i64(stage), modulus)
        if inverse { root = power_mod(root, modulus - 2, modulus) }
        for start := 0; start < n; start += stage {
            factor := i64(1)
            for offset := 0; offset < stage/2; offset += 1 {
                left := values[start + offset]
                right := (values[start + offset + stage/2] * factor) % modulus
                values[start + offset] = (left + right) % modulus
                values[start + offset + stage/2] = (left - right + modulus) % modulus
                factor = (factor * root) % modulus
            }
        }
    }
    if inverse {
        scale := power_mod(i64(n), modulus - 2, modulus)
        for i := 0; i < n; i += 1 { values[i] = (values[i] * scale) % modulus }
    }
}

convolution_residues :: proc "contextless" (input: [^]i64, n, m, transform_length: int,
    modulus, primitive_root: i64, result: ^[MAX_RESULT_LENGTH]i64) {
    a: [MAX_NTT_SIZE]i64
    b: [MAX_NTT_SIZE]i64
    for i := 0; i < n; i += 1 { a[i] = i64(u64(input[2+i]) % u64(modulus)) }
    for i := 0; i < m; i += 1 { b[i] = i64(u64(input[2+n+i]) % u64(modulus)) }
    transform(&a, transform_length, modulus, primitive_root, false)
    transform(&b, transform_length, modulus, primitive_root, false)
    for i := 0; i < transform_length; i += 1 { a[i] = (a[i] * b[i]) % modulus }
    transform(&a, transform_length, modulus, primitive_root, true)
    for i := 0; i < n+m-1; i += 1 { result[i] = a[i] }
}

positive_delta :: proc "contextless" (value, partial, modulus: i64) -> i64 {
    delta := value - partial
    if delta < 0 { delta += modulus }
    return delta
}

store_u64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: u64) {
    bits := value
    for byte := c.size_t(0); byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
convolution_mod_2_64 :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
    n_value, m_value := input[0], input[1]
    if n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH { return -1 }
    n, m := int(n_value), int(m_value)
    if length != c.size_t(2+n+m) { return -1 }
    result_length := n + m - 1
    transform_length := 1
    for transform_length < result_length { transform_length <<= 1 }
    output_bytes := 8 * result_length
    if output == nil || capacity < c.size_t(output_bytes) { return -2 }

    r0: [MAX_RESULT_LENGTH]i64
    r1: [MAX_RESULT_LENGTH]i64
    r2: [MAX_RESULT_LENGTH]i64
    r3: [MAX_RESULT_LENGTH]i64
    r4: [MAX_RESULT_LENGTH]i64
    convolution_residues(input, n, m, transform_length, P0, 3, &r0)
    convolution_residues(input, n, m, transform_length, P1, 3, &r1)
    convolution_residues(input, n, m, transform_length, P2, 7, &r2)
    convolution_residues(input, n, m, transform_length, P3, 3, &r3)
    convolution_residues(input, n, m, transform_length, P4, 5, &r4)

    p01_p2 := (P0 % P2) * (P1 % P2) % P2
    p01_p3 := (P0 % P3) * (P1 % P3) % P3
    p01_p4 := (P0 % P4) * (P1 % P4) % P4
    p012_p3 := p01_p3 * (P2 % P3) % P3
    p012_p4 := p01_p4 * (P2 % P4) % P4
    p0123_p4 := p012_p4 * (P3 % P4) % P4
    inv0_p1 := power_mod(P0 % P1, P1-2, P1)
    inv01_p2 := power_mod(p01_p2, P2-2, P2)
    inv012_p3 := power_mod(p012_p3, P3-2, P3)
    inv0123_p4 := power_mod(p0123_p4, P4-2, P4)
    for i := 0; i < result_length; i += 1 {
        t0 := r0[i]
        t1 := positive_delta(r1[i], t0 % P1, P1) * inv0_p1 % P1
        x01_p2 := (r0[i] % P2 + (P0 % P2)*t1) % P2
        t2 := positive_delta(r2[i], x01_p2, P2) * inv01_p2 % P2
        x012_p3 := (r0[i] % P3 + (P0 % P3)*t1 + p01_p3*t2) % P3
        t3 := positive_delta(r3[i], x012_p3, P3) * inv012_p3 % P3
        x0123_p4 := (r0[i] % P4 + (P0 % P4)*t1 + p01_p4*t2 + p012_p4*t3) % P4
        t4 := positive_delta(r4[i], x0123_p4, P4) * inv0123_p4 % P4
        value := u64(t0) + u64(P0)*u64(t1) + u64(P0)*u64(P1)*u64(t2)
            + u64(P0)*u64(P1)*u64(P2)*u64(t3)
            + u64(P0)*u64(P1)*u64(P2)*u64(P3)*u64(t4)
        store_u64_le(output, c.size_t(8*i), value)
    }
    return i64(output_bytes)
}
