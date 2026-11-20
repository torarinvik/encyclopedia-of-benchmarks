// Uncompiled chordal-graph optimal coloring draft.
package chordal_graph_optimal_coloring
import "core:c"
@(export)
chordal_graph_optimal_coloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 18 do return -1
    nv := input[0]
    if nv < 1 || nv > 16 || length != c.size_t(nv+1) do return -1
    n := int(nv)
    rows: [16]int = {}
    weight: [16]int = {}
    colors: [16]int = {}
    order: [16]int = {}
    for v := 0; v < n; v += 1 {
        if input[v+1] < 0 || input[v+1] >= i64(1 << uint(n)) || (input[v+1] & i64(1 << uint(v))) != 0 do return -1
        rows[v] = int(input[v+1]); colors[v] = -1
    }
    for v := 0; v < n; v += 1 { for u := 0; u < v; u += 1 {
        if ((rows[v] >> uint(u)) & 1) != ((rows[u] >> uint(v)) & 1) do return -1
    } }
    selected := 0
    for i := 0; i < n; i += 1 {
        v := -1
        for u := 0; u < n; u += 1 {
            if (selected & (1 << uint(u))) == 0 {
                if v < 0 { v = u } else if weight[u] > weight[v] { v = u }
            }
        }
        earlier := rows[v] & selected
        for j := 0; j < i; j += 1 {
            u := order[j]
            if (earlier & (1 << uint(u))) != 0 && (earlier & ~(rows[u] | (1 << uint(u)))) != 0 do return -2
        }
        order[i] = v; selected |= 1 << uint(v)
        for u := 0; u < n; u += 1 { if (selected & (1 << uint(u))) == 0 && (rows[v] & (1 << uint(u))) != 0 { weight[u] += 1 } }
    }
    maximum := 0
    for i := 0; i < n; i += 1 {
        v := order[i]; used := 0
        for u := 0; u < n; u += 1 { if (rows[v] & (1 << uint(u))) != 0 && colors[u] >= 0 { used |= 1 << uint(colors[u]) } }
        color := 0
        for (used & (1 << uint(color))) != 0 { color += 1 }
        colors[v] = color; maximum = max(maximum, color+1)
    }
    return i64(maximum)
}
