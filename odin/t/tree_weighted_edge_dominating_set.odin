// Uncompiled minimum-weight tree edge-domination draft.
package tree_weighted_edge_dominating_set
import "core:c"
@(export)
tree_weighted_edge_dominating_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 128 do return -1
    nv := input[0]
    if nv < 1 || nv > 64 || length != c.size_t(2*nv-1) do return -1
    n := int(nv)
    for v := 1; v < n; v += 1 {
        if input[v] < 0 || input[v] >= i64(v) || input[n+v-1] < 0 || input[n+v-1] > 1000000 do return -1
    }
    inf: i64 = 1000000000000
    selected: [64]i64 = {}
    closed: [64]i64 = {}
    pending: [64]i64 = {}
    for v := 0; v < n; v += 1 { selected[v] = inf }
    for v := n-1; v > 0; v -= 1 {
        p := int(input[v])
        skip := min(selected[v], closed[v])
        take := input[n+v-1] + min(selected[v], pending[v])
        selected[p] = min(inf, min(selected[p] + min(skip, take), pending[p] + take))
        closed[p] = min(inf, closed[p] + selected[v])
        pending[p] = min(inf, pending[p] + skip)
    }
    return min(selected[0], closed[0])
}
