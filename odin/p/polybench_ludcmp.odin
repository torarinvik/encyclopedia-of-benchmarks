package polybench_ludcmp

MAX_DIMENSION :: 64
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT :: f64(-1e300)

@(export)
polybench_ludcmp :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return INVALID_RESULT
    n := int(values[0])
    var a: [MAX_CELLS]f64
    var product: [MAX_CELLS]f64
    var b: [MAX_DIMENSION]f64
    var x: [MAX_DIMENSION]f64
    var y: [MAX_DIMENSION]f64
    for i := 0; i < n; i += 1 {
        x[i] = 0.0
        y[i] = 0.0
        b[i] = (f64(i + 1) / f64(n)) / 2.0 + 4.0
    }
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
            w := a[i * n + j]
            for k := 0; k < j; k += 1 { w = w - a[i * n + k] * a[k * n + j] }
            a[i * n + j] = w / a[j * n + j]
        }
        for j := i; j < n; j += 1 {
            w := a[i * n + j]
            for k := 0; k < i; k += 1 { w = w - a[i * n + k] * a[k * n + j] }
            a[i * n + j] = w
        }
    }
    for i := 0; i < n; i += 1 {
        w := b[i]
        for j := 0; j < i; j += 1 { w = w - a[i * n + j] * y[j] }
        y[i] = w
    }
    for i := n - 1; i >= 0; i -= 1 {
        w := y[i]
        for j := i + 1; j < n; j += 1 { w = w - a[i * n + j] * x[j] }
        x[i] = w / a[i * n + i]
    }
    result := f64(0)
    for i := 0; i < n; i += 1 { result += x[i] }
    return result
}
