//! Uncompiled chordal-graph optimal coloring draft.
#[no_mangle]
pub unsafe extern "C" fn chordal_graph_optimal_coloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=18).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if !(1..=16).contains(&nv) || length != nv as usize + 1 { return -1; }
    let n = nv as usize;
    let (mut rows, mut weight, mut colors, mut order) = ([0u32;16], [0usize;16], [-1i32;16], [0usize;16]);
    for v in 0..n {
        if values[v+1] < 0 || values[v+1] >= (1i64 << n) || values[v+1] & (1i64 << v) != 0 { return -1; }
        rows[v] = values[v+1] as u32;
    }
    for v in 0..n { for u in 0..v {
        if (rows[v] & (1 << u) != 0) != (rows[u] & (1 << v) != 0) { return -1; }
    } }
    let mut selected = 0u32;
    for i in 0..n {
        let mut v = None;
        for u in 0..n {
            if selected & (1 << u) == 0 && v.map_or(true, |old| weight[u] > weight[old]) { v = Some(u); }
        }
        let v = v.unwrap();
        let earlier = rows[v] & selected;
        for &u in &order[..i] {
            if earlier & (1 << u) != 0 && earlier & !(rows[u] | (1 << u)) != 0 { return -2; }
        }
        order[i] = v; selected |= 1 << v;
        for u in 0..n { if selected & (1 << u) == 0 && rows[v] & (1 << u) != 0 { weight[u] += 1; } }
    }
    let mut maximum = 0;
    for &v in &order[..n] {
        let mut used = 0u32;
        for u in 0..n { if rows[v] & (1 << u) != 0 && colors[u] >= 0 { used |= 1 << colors[u]; } }
        let mut color = 0; while used & (1 << color) != 0 { color += 1; }
        colors[v] = color; maximum = maximum.max(color + 1);
    }
    maximum as i64
}
