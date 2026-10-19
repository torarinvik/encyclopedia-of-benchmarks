package polybench_symm

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: f64(-1e300)

@(export)
polybench_symm :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION || values[1] < 1 || values[1] > MAX_DIMENSION do return INVALID_RESULT
    m, n := int(values[0]), int(values[1])
    var a: [MAX_CELLS]f64
    var b: [MAX_CELLS]f64
    var c: [MAX_CELLS]f64
    alpha, beta := f64(1.5), f64(1.2)
    for i := 0; i < m; i += 1 { for j := 0; j < n; j += 1 {
        c[i * n + j] = f64((i + j) % 100) / f64(m)
        b[i * n + j] = f64((n + i - j) % 100) / f64(m)
    }}
    for i := 0; i < m; i += 1 { for j := 0; j < m; j += 1 {
        if j <= i { a[i * m + j] = f64((i + j) % 100) / f64(m) } else { a[i * m + j] = -999.0 }
    }}
    for i := 0; i < m; i += 1 { for j := 0; j < n; j += 1 {
        temp2 := f64(0)
        for k := 0; k < i; k += 1 {
            c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k]
            temp2 = temp2 + b[k * n + j] * a[i * m + k]
        }
        c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2
    }}
    result := f64(0)
    for i := 0; i < m; i += 1 { for j := 0; j < n; j += 1 { result += c[i * n + j] } }
    return result
}
