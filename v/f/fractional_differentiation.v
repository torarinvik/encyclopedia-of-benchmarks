module fractional_differentiation

@[export: 'fractional_differentiation']
pub fn fractional_differentiation(values &i64, length usize) f64 {
    if unsafe { values == nil } || length < 4 || length > 18 { return -1.0e300 }
    n := int(length) - 2
    d_units := unsafe { values[0] }
    window := unsafe { values[1] }
    if d_units < 0 || d_units > 1000000 || window < 1 || window > 8 || n <= int(window) || n > 16 { return -1.0e300 }
    unsafe { for i in 0 .. n { if values[i+2] < -1000000 || values[i+2] > 1000000 { return -1.0e300 } } }
    d := f64(d_units) / 1000000.0
    mut weights := [8]f64{}
    weights[0] = 1.0
    for k in 1 .. int(window) { weights[k] = -weights[k-1] * (d - f64(k) + 1.0) / f64(k) }
    mut result := 0.0
    unsafe { for j in 0 .. int(window) { result += weights[j] * (f64(values[2+n-1-j]) / 1000.0) } }
    return result
}
