const INVALID_RESULT: f64 = -1.0e300;
const MAX_NODES: i64 = 100000;

pub export fn density(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3) return INVALID_RESULT;
    const nodes = values[0];
    const edges = values[1];
    const directed = values[2];
    if (nodes < 2 or nodes > MAX_NODES or (directed != 0 and directed != 1)) return INVALID_RESULT;
    var max_edges = nodes * (nodes - 1);
    if (directed == 0) max_edges /= 2;
    if (edges < 0 or edges > max_edges) return INVALID_RESULT;
    const factor: f64 = if (directed == 1) 1.0 else 2.0;
    return (factor * @as(f64, @floatFromInt(edges))) /
        (@as(f64, @floatFromInt(nodes)) * @as(f64, @floatFromInt(nodes - 1)));
}
