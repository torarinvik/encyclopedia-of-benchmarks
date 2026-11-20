// Uncompiled minimum tree path-partition draft.
package tree_minimum_path_partition
import "core:c"
@(export)
tree_minimum_path_partition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 65 do return -1
    nv := input[0]
    if nv < 1 || nv > 64 || length != c.size_t(nv) do return -1
    n := int(nv)
    for v := 1; v < n; v += 1 { if input[v] < 0 || input[v] >= i64(v) do return -1 }
    base: [64]i64 = {}
    first: [64]i64 = {}
    second: [64]i64 = {}
    for v := n-1; v > 0; v -= 1 {
        p := int(input[v])
        best := base[v] + first[v] + second[v]
        gain := 1 + base[v] + first[v] - best
        base[p] += best
        if gain > first[p] { second[p] = first[p]; first[p] = gain } else if gain > second[p] { second[p] = gain }
    }
    return nv - base[0] - first[0] - second[0]
}
