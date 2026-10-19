package spectral_norm

import "core:math"

MAX_DIMENSION :: 64
INVALID_RESULT :: f64(-1e300)

matrix_entry :: proc(i, j: int) -> f64 {
    triangular := (i + j) * (i + j + 1) / 2
    return 1.0 / f64(triangular + i + 1)
}

multiply_a :: proc(n: int, input, output: [^]f64) {
    for i := 0; i < n; i += 1 {
        total := f64(0)
        for j := 0; j < n; j += 1 { total += matrix_entry(i, j) * input[j] }
        output[i] = total
    }
}

multiply_at :: proc(n: int, input, output: [^]f64) {
    for i := 0; i < n; i += 1 {
        total := f64(0)
        for j := 0; j < n; j += 1 { total += matrix_entry(j, i) * input[j] }
        output[i] = total
    }
}

multiply_ata :: proc(n: int, input, output, temporary: [^]f64) {
    multiply_a(n, input, temporary)
    multiply_at(n, temporary, output)
}

@(export)
spectral_norm :: proc "c" (values: [^]i64, length: u64) -> f64 {
    if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return INVALID_RESULT
    n := int(values[0])
    u: [MAX_DIMENSION]f64
    v: [MAX_DIMENSION]f64
    temporary: [MAX_DIMENSION]f64
    for i := 0; i < n; i += 1 { u[i] = 1.0 }
    for _ := 0; _ < 10; _ += 1 {
        multiply_ata(n, &u[0], &v[0], &temporary[0])
        multiply_ata(n, &v[0], &u[0], &temporary[0])
    }
    v_b_v := f64(0)
    v_v := f64(0)
    for i := 0; i < n; i += 1 {
        v_b_v += u[i] * v[i]
        v_v += v[i] * v[i]
    }
    return math.sqrt(v_b_v / v_v)
}
