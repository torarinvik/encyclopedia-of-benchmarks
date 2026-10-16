module density

const invalid_result = -1.0e300
const max_nodes = 100000

@[export: 'density']
pub fn density(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 3 { return invalid_result }
    unsafe {
        nodes := values[0]
        edges := values[1]
        directed := values[2]
        if nodes < 2 || nodes > max_nodes || (directed != 0 && directed != 1) { return invalid_result }
        mut max_edges := nodes * (nodes - 1)
        if directed == 0 { max_edges /= 2 }
        if edges < 0 || edges > max_edges { return invalid_result }
        factor := if directed == 1 { 1.0 } else { 2.0 }
        return (factor * f64(edges)) / (f64(nodes) * f64(nodes - 1))
    }
}
