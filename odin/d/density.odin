package density

import "core:c"

INVALID_RESULT :: -1.0e300
MAX_NODES :: 100000

@(export)
density :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 3 do return INVALID_RESULT
    nodes := values[0]
    edges := values[1]
    directed := values[2]
    if nodes < 2 || nodes > MAX_NODES || (directed != 0 && directed != 1) do return INVALID_RESULT
    max_edges := nodes * (nodes - 1)
    if directed == 0 do max_edges /= 2
    if edges < 0 || edges > max_edges do return INVALID_RESULT
    factor := if directed == 1 {1.0} else {2.0}
    return (factor * f64(edges)) / (f64(nodes) * f64(nodes - 1))
}
