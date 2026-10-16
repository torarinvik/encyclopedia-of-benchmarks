const INVALID_RESULT: f64 = -1.0e300;
const MAX_NODES: i64 = 100000;

#[no_mangle]
pub unsafe extern "C" fn density(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let nodes = *values;
    let edges = *values.add(1);
    let directed = *values.add(2);
    if !(2..=MAX_NODES).contains(&nodes) || (directed != 0 && directed != 1) { return INVALID_RESULT; }
    let mut max_edges = nodes * (nodes - 1);
    if directed == 0 { max_edges /= 2; }
    if edges < 0 || edges > max_edges { return INVALID_RESULT; }
    let factor = if directed == 1 { 1.0 } else { 2.0 };
    (factor * edges as f64) / (nodes as f64 * (nodes - 1) as f64)
}
