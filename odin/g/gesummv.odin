package gesummv

MAX_DIMENSION :: 64
INVALID_RESULT :: f64(-1e300)

@(export)
gesummv :: proc "c" (values: [^]i64, length: u64) -> f64 {
    if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return INVALID_RESULT
    n := int(values[0])
    x: [MAX_DIMENSION]f64
    for i := 0; i < n; i += 1 { x[i] = f64(i % n) / f64(n) }
    result := f64(0)
    for i := 0; i < n; i += 1 {
        temporary := f64(0)
        y := f64(0)
        for j := 0; j < n; j += 1 {
            a := f64((i * j + 1) % n) / f64(n)
            b := f64((i * j + 2) % n) / f64(n)
            temporary = a * x[j] + temporary
            y = b * x[j] + y
        }
        y = 1.5 * temporary + 1.2 * y
        result += y
    }
    return result
}
