package doitgen

MAX_DIMENSION :: 16
MAX_A_CELLS :: MAX_DIMENSION * MAX_DIMENSION * MAX_DIMENSION
MAX_C4_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
doitgen :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 3 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION || values[2] < 1 || values[2] > MAX_DIMENSION do return INVALID_RESULT
    nr, nq, np := int(values[0]), int(values[1]), int(values[2])
    var a: [MAX_A_CELLS]f64
    var c4: [MAX_C4_CELLS]f64
    var sums: [MAX_DIMENSION]f64
    for r := 0; r < nr; r += 1 {
        for q := 0; q < nq; q += 1 {
            for p := 0; p < np; p += 1 { a[(r * nq + q) * np + p] = f64((r * q + p) % np) / f64(np) }
        }
    }
    for i := 0; i < np; i += 1 {
        for j := 0; j < np; j += 1 { c4[i * np + j] = f64((i * j) % np) / f64(np) }
    }
    for r := 0; r < nr; r += 1 {
        for q := 0; q < nq; q += 1 {
            for p := 0; p < np; p += 1 {
                sums[p] = 0.0
                for s := 0; s < np; s += 1 { sums[p] += a[(r * nq + q) * np + s] * c4[s * np + p] }
            }
            for p := 0; p < np; p += 1 { a[(r * nq + q) * np + p] = sums[p] }
        }
    }
    checksum := f64(0)
    for r := 0; r < nr; r += 1 {
        for q := 0; q < nq; q += 1 {
            for p := 0; p < np; p += 1 { checksum += a[(r * nq + q) * np + p] }
        }
    }
    return checksum
}
