package berkowitz_characteristic_polynomial
import "core:c"

MAX_N :: 7
MAX_INPUT_WORDS :: 52

residue :: proc(value, modulus: i64) -> i64 {
    result := value % modulus
    if result < 0 { result += modulus }
    return result
}

negative_residue :: proc(value, modulus: i64) -> i64 {
    if value == 0 do return 0
    return modulus - value
}

store_i64_le :: proc(output: [^]u8, word: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[word*8+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
berkowitz_characteristic_polynomial :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8,
    output_capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT_WORDS do return -1
    n64 := input[0]
    modulus := input[1]
    if n64 < 1 || n64 > MAX_N || modulus < 2 || modulus > 1000000000 do return -1
    n := int(n64)
    if int(length) != 2+n*n do return -1

    matrix: [MAX_N*MAX_N]i64
    for i := 0; i < n*n; i += 1 {
        entry := input[i+2]
        if entry < -1000000 || entry > 1000000 do return -1
        matrix[i] = residue(entry, modulus)
    }
    output_bytes := (n+1)*8
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2

    coefficients: [MAX_N+1]i64
    current: [MAX_N+1]i64
    toeplitz: [MAX_N+1]i64
    vector: [MAX_N]i64
    next_vector: [MAX_N]i64
    coefficients[0] = 1
    for size := 1; size <= n; size += 1 {
        start := n-size
        block := size-1
        for i := 0; i <= size; i += 1 { toeplitz[i] = 0 }
        toeplitz[0] = 1
        toeplitz[1] = negative_residue(matrix[start*n+start], modulus)
        for row := 0; row < block; row += 1 {
            vector[row] = matrix[(start+1+row)*n+start]
        }
        for power := 0; power < block; power += 1 {
            dot: i64 = 0
            for col := 0; col < block; col += 1 {
                dot = (dot + matrix[start*n+start+1+col]*vector[col]) % modulus
            }
            toeplitz[power+2] = negative_residue(dot, modulus)
            for row := 0; row < block; row += 1 {
                value: i64 = 0
                for col := 0; col < block; col += 1 {
                    value = (value + matrix[(start+1+row)*n+start+1+col]
                        *vector[col]) % modulus
                }
                next_vector[row] = value
            }
            for row := 0; row < block; row += 1 { vector[row] = next_vector[row] }
        }
        for i := 0; i <= size; i += 1 {
            value: i64 = 0
            last_child := i
            if last_child >= size { last_child = size-1 }
            for j := 0; j <= last_child; j += 1 {
                value = (value + toeplitz[i-j]*coefficients[j]) % modulus
            }
            current[i] = value
        }
        for i := 0; i <= size; i += 1 { coefficients[i] = current[i] }
    }
    for i := 0; i <= n; i += 1 { store_i64_le(output, i, coefficients[i]) }
    return i64(output_bytes)
}
