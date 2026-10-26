package color_coding_k_path

import "core:c"

// Subset/endpoint dynamic program for a colorful path of exactly k vertices.
@(export)
color_coding_k_path :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil do return -2
    if length < 3 || length > 147 do return -1
    nv, mv, kv := values[0], values[1], values[2]
    if nv < 1 || nv > 12 || mv < 0 || mv > 66 || kv < 1 || kv > 6 || kv > nv do return -1
    n, m, k := int(nv), int(mv), int(kv)
    split := 3+n
    if int(length) != split+2*m do return -1
    colors: [12]int
    adj: [12]u16
    for v := 0; v < n; v += 1 {
        if values[3+v] < 0 || values[3+v] >= kv do return -1
        colors[v] = int(values[3+v])
    }
    for e := 0; e < m; e += 1 {
        av, bv := values[split+2*e], values[split+2*e+1]
        if av < 0 || bv < 0 || av >= nv || bv >= nv || av == bv do return -1
        a, b := int(av), int(bv)
        bit := u16(1) << b
        if adj[a] & bit != 0 do return -1
        adj[a] |= bit
        adj[b] |= u16(1) << a
    }
    dp: [64][12]bool
    for v := 0; v < n; v += 1 { dp[1 << colors[v]][v] = true }
    full := (1 << k)-1
    found := false
    for mask := 1; mask <= full && !found; mask += 1 {
        for v := 0; v < n; v += 1 {
            if !dp[mask][v] do continue
            if mask == full { found = true; break }
            for u := 0; u < n; u += 1 {
                bit := 1 << colors[u]
                if adj[v] & (u16(1) << u) != 0 && mask & bit == 0 do dp[mask|bit][u] = true
            }
        }
    }
    if output_capacity < 8 || output == nil do return -2
    if found { output[0] = 1 } else { output[0] = 0 }
    for i := 1; i < 8; i += 1 { output[i] = 0 }
    return 8
}
