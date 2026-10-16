package newton_raphson
import "core:c"
@(export)
newton_raphson :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 do return -1.0e300
    n,q:=values[0],values[1]
    if n<2 || n>4 || q<4 || q>8 do return -1.0e300
    x:=f64(q)/4.0
    for _ in 0..<8 { x=0.5*(x+f64(n)/x) }
    return x
}
