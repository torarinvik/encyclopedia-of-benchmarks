@[export: 'federated_averaging']
pub fn federated_averaging(input &i64, length usize) f64 {
    invalid := -1.0e300
    if isnil(input) || length < 3 || length > 17 { return invalid }
    clients := unsafe { input[0] }
    if clients < 1 || clients > 8 || length != usize(1 + 2 * clients) { return invalid }
    mut total := 0.0
    for i in i64(0)..clients {
        weight := unsafe { input[1 + i] }
        if weight < 0 || weight > 1000 { return invalid }
        total += f64(weight)
    }
    if total <= 0.0 { return invalid }
    mut result := 0.0
    for i in i64(0)..clients {
        value := unsafe { input[1 + clients + i] }
        if value < -1000 || value > 1000 { return invalid }
        normalized := f64(unsafe { input[1 + i] }) / total
        result += normalized * f64(value)
    }
    return result
}
