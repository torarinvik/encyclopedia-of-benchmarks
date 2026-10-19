package atax

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
atax :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION || values[1] < 1 || values[1] > MAX_DIMENSION do return INVALID_RESULT
    m, n := int(values[0]), int(values[1])
    var matrix: [MAX_CELLS]f64
    var x: [MAX_DIMENSION]f64
    var y: [MAX_DIMENSION]f64
    var temporary: [MAX_DIMENSION]f64
    fn_value := f64(n)
    for i := 0; i < n; i += 1 { x[i] = 1.0 + f64(i) / fn_value }
    for i := 0; i < m; i += 1 { for j := 0; j < n; j += 1 {
        matrix[i * n + j] = f64((i + j) % n) / f64(5 * m)
    }}
    for i := 0; i < n; i += 1 { y[i] = 0.0 }
    for i := 0; i < m; i += 1 {
        temporary[i] = 0.0
        for j := 0; j < n; j += 1 { temporary[i] = temporary[i] + matrix[i * n + j] * x[j] }
        for j := 0; j < n; j += 1 { y[j] = y[j] + matrix[i * n + j] * temporary[i] }
    }
    checksum := f64(0)
    for j := 0; j < n; j += 1 { checksum += y[j] }
    return checksum
}
