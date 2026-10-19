package covariance

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
covariance :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 2 || values[0] < 2 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION do return INVALID_RESULT
    n, m := int(values[0]), int(values[1])
    float_n := f64(n)
    var data: [MAX_CELLS]f64
    var cov: [MAX_CELLS]f64
    var mean: [MAX_DIMENSION]f64
    for i := 0; i < n; i += 1 {
        for j := 0; j < m; j += 1 { data[i * m + j] = (f64(i) * f64(j)) / f64(m) }
    }
    for j := 0; j < m; j += 1 {
        mean[j] = 0.0
        for i := 0; i < n; i += 1 { mean[j] += data[i * m + j] }
        mean[j] /= float_n
    }
    for i := 0; i < n; i += 1 {
        for j := 0; j < m; j += 1 { data[i * m + j] -= mean[j] }
    }
    for i := 0; i < m; i += 1 {
        for j := i; j < m; j += 1 {
            cov[i * m + j] = 0.0
            for k := 0; k < n; k += 1 { cov[i * m + j] += data[k * m + i] * data[k * m + j] }
            cov[i * m + j] /= float_n - 1.0
            cov[j * m + i] = cov[i * m + j]
        }
    }
    checksum := f64(0)
    for i := 0; i < m; i += 1 {
        for j := 0; j < m; j += 1 { checksum += cov[i * m + j] }
    }
    return checksum
}
