package polybench_cholesky

import "core:math"

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: f64(-1e300)

@(export)
polybench_cholesky :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return INVALID_RESULT
    n := int(values[0])
    var a: [MAX_CELLS]f64
    var product: [MAX_CELLS]f64
    for i := 0; i < n; i += 1 {
        for j := 0; j <= i; j += 1 { a[i * n + j] = f64(-(j % n)) / f64(n) + 1.0 }
        for j := i + 1; j < n; j += 1 { a[i * n + j] = 0.0 }
        a[i * n + i] = 1.0
    }
    for r := 0; r < n; r += 1 { for s := 0; s < n; s += 1 { product[r * n + s] = 0.0 } }
    for t := 0; t < n; t += 1 { for r := 0; r < n; r += 1 { for s := 0; s < n; s += 1 {
        product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t]
    }}}
    for r := 0; r < n; r += 1 { for s := 0; s < n; s += 1 { a[r * n + s] = product[r * n + s] } }
    for i := 0; i < n; i += 1 {
        for j := 0; j < i; j += 1 {
            for k := 0; k < j; k += 1 { a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k] }
            a[i * n + j] = a[i * n + j] / a[j * n + j]
        }
        for k := 0; k < i; k += 1 { a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k] }
        a[i * n + i] = math.sqrt(a[i * n + i])
    }
    result := f64(0)
    for i := 0; i < n; i += 1 { for j := 0; j <= i; j += 1 { result += a[i * n + j] } }
    return result
}
