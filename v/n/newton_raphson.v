module newton_raphson
@[export: 'newton_raphson']
pub fn newton_raphson(values &i64, length usize) f64 {
    if isnil(values) || length != 2 { return -1e300 }
    n:=unsafe { values[0] }; q:=unsafe { values[1] }
    if n<2 || n>4 || q<4 || q>8 { return -1e300 }
    mut x:=f64(q)/4.0
    for _ in 0..8 { x=0.5*(x+f64(n)/x) }
    return x
}
