package gemver

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
gemver :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return INVALID_RESULT
    n := int(values[0])
    alpha, beta := 1.5, 1.2
    var a: [MAX_CELLS]f64
    var u1, v1, u2, v2, w, x, y, z: [MAX_DIMENSION]f64
    for i := 0; i < n; i += 1 {
        u1[i] = f64(i)
        u2[i] = (f64(i + 1) / f64(n)) / 2.0
        v1[i] = (f64(i + 1) / f64(n)) / 4.0
        v2[i] = (f64(i + 1) / f64(n)) / 6.0
        y[i] = (f64(i + 1) / f64(n)) / 8.0
        z[i] = (f64(i + 1) / f64(n)) / 9.0
        for j := 0; j < n; j += 1 { a[i * n + j] = f64((i * j) % n) / f64(n) }
    }
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 { a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j] }
    }
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 { x[i] = x[i] + beta * a[j * n + i] * y[j] }
    }
    for i := 0; i < n; i += 1 { x[i] = x[i] + z[i] }
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 { w[i] = w[i] + alpha * a[i * n + j] * x[j] }
    }
    checksum := f64(0)
    for i := 0; i < n; i += 1 { checksum += w[i] }
    return checksum
}
