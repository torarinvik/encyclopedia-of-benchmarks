package three_mm

MAX_DIMENSION :: 16
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
three_mm :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 5 do return INVALID_RESULT
    for i := 0; i < 5; i += 1 {
        if values[i] < 1 || values[i] > MAX_DIMENSION do return INVALID_RESULT
    }
    ni, nj, nk, nl, nm := int(values[0]), int(values[1]), int(values[2]), int(values[3]), int(values[4])
    var a, b, c, d, e, f, g: [MAX_CELLS]f64
    for i := 0; i < ni; i += 1 {
        for k := 0; k < nk; k += 1 { a[i * nk + k] = f64((i * k + 1) % ni) / f64(5 * ni) }
    }
    for k := 0; k < nk; k += 1 {
        for j := 0; j < nj; j += 1 { b[k * nj + j] = f64((k * (j + 1) + 2) % nj) / f64(5 * nj) }
    }
    for i := 0; i < nj; i += 1 {
        for j := 0; j < nm; j += 1 { c[i * nm + j] = f64((i * (j + 3)) % nl) / f64(5 * nl) }
    }
    for i := 0; i < nm; i += 1 {
        for j := 0; j < nl; j += 1 { d[i * nl + j] = f64((i * (j + 2) + 2) % nk) / f64(5 * nk) }
    }
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nj; j += 1 {
            e[i * nj + j] = 0
            for k := 0; k < nk; k += 1 { e[i * nj + j] += a[i * nk + k] * b[k * nj + j] }
        }
    }
    for i := 0; i < nj; i += 1 {
        for j := 0; j < nl; j += 1 {
            f[i * nl + j] = 0
            for k := 0; k < nm; k += 1 { f[i * nl + j] += c[i * nm + k] * d[k * nl + j] }
        }
    }
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nl; j += 1 {
            g[i * nl + j] = 0
            for k := 0; k < nj; k += 1 { g[i * nl + j] += e[i * nj + k] * f[k * nl + j] }
        }
    }
    checksum := f64(0)
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nl; j += 1 { checksum += g[i * nl + j] }
    }
    return checksum
}
