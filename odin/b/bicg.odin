package bicg

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
bicg :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION || values[1] < 1 || values[1] > MAX_DIMENSION do return INVALID_RESULT
    m, n := int(values[0]), int(values[1])
    var matrix: [MAX_CELLS]f64
    var p: [MAX_DIMENSION]f64
    var r: [MAX_DIMENSION]f64
    var s: [MAX_DIMENSION]f64
    var q: [MAX_DIMENSION]f64
    for i := 0; i < m; i += 1 { p[i] = f64(i % m) / f64(m) }
    for i := 0; i < n; i += 1 {
        r[i] = f64(i % n) / f64(n)
        for j := 0; j < m; j += 1 { matrix[i * m + j] = f64((i * (j + 1)) % n) / f64(n) }
    }
    for i := 0; i < m; i += 1 { s[i] = 0.0 }
    for i := 0; i < n; i += 1 {
        q[i] = 0.0
        for j := 0; j < m; j += 1 {
            s[j] = s[j] + r[i] * matrix[i * m + j]
            q[i] = q[i] + matrix[i * m + j] * p[j]
        }
    }
    checksum := f64(0)
    for j := 0; j < m; j += 1 { checksum += s[j] }
    for i := 0; i < n; i += 1 { checksum += q[i] }
    return checksum
}
