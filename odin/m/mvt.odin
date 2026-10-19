package mvt

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: -1.0e300

@(export)
mvt :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return INVALID_RESULT
    n := int(values[0])
    var x1: [MAX_DIMENSION]f64
    var x2: [MAX_DIMENSION]f64
    var y1: [MAX_DIMENSION]f64
    var y2: [MAX_DIMENSION]f64
    var matrix: [MAX_CELLS]f64
    for i := 0; i < n; i += 1 {
        x1[i] = f64(i % n) / f64(n)
        x2[i] = f64((i + 1) % n) / f64(n)
        y1[i] = f64((i + 3) % n) / f64(n)
        y2[i] = f64((i + 4) % n) / f64(n)
        for j := 0; j < n; j += 1 { matrix[i * n + j] = f64((i * j) % n) / f64(n) }
    }
    for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { x1[i] = x1[i] + matrix[i * n + j] * y1[j] } }
    for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { x2[i] = x2[i] + matrix[j * n + i] * y2[j] } }
    checksum := f64(0)
    for i := 0; i < n; i += 1 { checksum += x1[i] }
    for i := 0; i < n; i += 1 { checksum += x2[i] }
    return checksum
}
