package gemm

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
gemm :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 3 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION || values[2] < 1 || values[2] > MAX_DIMENSION do return INVALID_RESULT
    ni, nj, nk := int(values[0]), int(values[1]), int(values[2])
    alpha, beta := 1.5, 1.2
    var c: [MAX_CELLS]f64
    var a: [MAX_CELLS]f64
    var b: [MAX_CELLS]f64
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nj; j += 1 { c[i * nj + j] = f64((i * j + 1) % ni) / f64(ni) }
    }
    for i := 0; i < ni; i += 1 {
        for k := 0; k < nk; k += 1 { a[i * nk + k] = f64((i * (k + 1)) % nk) / f64(nk) }
    }
    for k := 0; k < nk; k += 1 {
        for j := 0; j < nj; j += 1 { b[k * nj + j] = f64((k * (j + 2)) % nj) / f64(nj) }
    }
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nj; j += 1 { c[i * nj + j] *= beta }
        for k := 0; k < nk; k += 1 {
            for j := 0; j < nj; j += 1 { c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j] }
        }
    }
    checksum := f64(0)
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nj; j += 1 { checksum += c[i * nj + j] }
    }
    return checksum
}
