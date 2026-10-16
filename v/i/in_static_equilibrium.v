module in_static_equilibrium

const invalid_result = i64(-1)

@[export: 'in_static_equilibrium']
pub fn in_static_equilibrium(values &i64, length usize) i64 {
    if unsafe { values == nil } || length < 5 { return invalid_result }
    n_value := unsafe { values[0] }
    if n_value < 1 || n_value > 100 || length != 1 + 4 * usize(n_value) { return invalid_result }
    n := int(n_value)
    mut total_moment := i64(0)
    for i in 0 .. n {
        fx := unsafe { values[1 + i] }
        fy := unsafe { values[1 + n + i] }
        lx := unsafe { values[1 + 2 * n + i] }
        ly := unsafe { values[1 + 3 * n + i] }
        if fx < -1000 || fx > 1000 || fy < -1000 || fy > 1000 || lx < -1000 || lx > 1000 || ly < -1000 || ly > 1000 { return invalid_result }
        total_moment += lx * fy - ly * fx
    }
    return if total_moment == 0 { 1 } else { 0 }
}
