package two_mm

MAX_DIMENSION :: 16
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
two_mm :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 4 do return INVALID_RESULT
    for i := 0; i < 4; i += 1 {
        if values[i] < 1 || values[i] > MAX_DIMENSION do return INVALID_RESULT
    }
    ni, nj, nk, nl := int(values[0]), int(values[1]), int(values[2]), int(values[3])
    alpha, beta := 1.5, 1.2
    var a, b, c, d, tmp: [MAX_CELLS]f64
    for i := 0; i < ni; i += 1 {
        for k := 0; k < nk; k += 1 { a[i * nk + k] = f64((i * k + 1) % ni) / f64(ni) }
    }
    for k := 0; k < nk; k += 1 {
        for j := 0; j < nj; j += 1 { b[k * nj + j] = f64((k * (j + 1)) % nj) / f64(nj) }
    }
    for j := 0; j < nj; j += 1 {
        for l := 0; l < nl; l += 1 { c[j * nl + l] = f64((j * (l + 3) + 1) % nl) / f64(nl) }
    }
    for i := 0; i < ni; i += 1 {
        for l := 0; l < nl; l += 1 { d[i * nl + l] = f64((i * (l + 2)) % nk) / f64(nk) }
    }
    for i := 0; i < ni; i += 1 {
        for j := 0; j < nj; j += 1 {
            tmp[i * nj + j] = 0
            for k := 0; k < nk; k += 1 { tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j] }
        }
    }
    for i := 0; i < ni; i += 1 {
        for l := 0; l < nl; l += 1 {
            d[i * nl + l] *= beta
            for j := 0; j < nj; j += 1 { d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l] }
        }
    }
    checksum := f64(0)
    for i := 0; i < ni; i += 1 {
        for l := 0; l < nl; l += 1 { checksum += d[i * nl + l] }
    }
    return checksum
}
