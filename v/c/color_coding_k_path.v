module color_coding_k_path

// Subset/endpoint dynamic program for a colorful path of exactly k vertices.
@[export: 'color_coding_k_path']
pub fn color_coding_k_path(values &i64, length usize, output &u8, output_capacity usize) i64 {
    unsafe {
        if length < 3 || length > 147 { return -1 }
        nv := values[0]; mv := values[1]; kv := values[2]
        if nv < 1 || nv > 12 || mv < 0 || mv > 66 || kv < 1 || kv > 6 || kv > nv { return -1 }
        n := int(nv); m := int(mv); k := int(kv); split := 3+n
        if int(length) != split+2*m { return -1 }
        mut colors := [12]int{}
        mut adj := [12]u16{}
        for v := 0; v < n; v++ {
            if values[3+v] < 0 || values[3+v] >= kv { return -1 }
            colors[v] = int(values[3+v])
        }
        for e := 0; e < m; e++ {
            av := values[split+2*e]; bv := values[split+2*e+1]
            if av < 0 || bv < 0 || av >= nv || bv >= nv || av == bv { return -1 }
            a := int(av); b := int(bv); bit := u16(1) << b
            if adj[a] & bit != 0 { return -1 }
            adj[a] |= bit; adj[b] |= u16(1) << a
        }
        mut dp := [64][12]bool{}
        for v := 0; v < n; v++ { dp[1 << colors[v]][v] = true }
        full := (1 << k)-1
        mut found := false
        for mask := 1; mask <= full && !found; mask++ {
            for v := 0; v < n; v++ {
                if !dp[mask][v] { continue }
                if mask == full { found = true; break }
                for u := 0; u < n; u++ {
                    bit := 1 << colors[u]
                    if adj[v] & (u16(1) << u) != 0 && mask & bit == 0 { dp[mask|bit][u] = true }
                }
            }
        }
        if output_capacity < 8 { return -2 }
        if found { output[0] = 1 } else { output[0] = 0 }
        for i := 1; i < 8; i++ { output[i] = 0 }
        return 8
    }
}
