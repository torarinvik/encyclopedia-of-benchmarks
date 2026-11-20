const CW_P: usize = 6;
const CW_L: usize = 8;
const CW_T: usize = 64;
const CW_NODES: usize = 33;
const CW_INPUT: usize = 105;

fn cw_is_suffix(v: usize, u: usize, depth: &[usize; CW_NODES],
                path: &[[i64; CW_L]; CW_NODES]) -> bool {
    if depth[v] >= depth[u] { return false; }
    let offset = depth[u] - depth[v];
    for i in 0..depth[v] {
        if path[v][i] != path[u][offset + i] { return false; }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn commentz_walter(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > CW_INPUT { return -1; }
    let pv = *values;
    let nv = *values.add(1);
    if pv < 1 || pv > CW_P as i64 || nv < 0 || nv > CW_T as i64 { return -1; }
    let p = pv as usize;
    let n = nv as usize;
    if length < 2 + p { return -1; }
    let mut lens = [0usize; CW_P];
    let mut total = 0usize;
    let mut shortest = CW_L + 1;
    for i in 0..p {
        let raw = *values.add(2 + i);
        if raw < 1 || raw > CW_L as i64 { return -1; }
        lens[i] = raw as usize;
        total += lens[i];
        shortest = shortest.min(lens[i]);
    }
    if total > 32 || length != 2 + p + total + n { return -1; }
    let mut patterns = [[0i64; CW_L]; CW_P];
    let mut text = [0i64; CW_T];
    let mut at = 2 + p;
    for i in 0..p {
        for j in 0..lens[i] {
            let symbol = *values.add(at);
            at += 1;
            if !(1..=4).contains(&symbol) { return -1; }
            patterns[i][j] = symbol;
        }
        for prior in 0..i {
            if lens[prior] == lens[i] && patterns[prior][..lens[i]] == patterns[i][..lens[i]] {
                return -1;
            }
        }
    }
    for i in 0..n {
        let symbol = *values.add(at);
        at += 1;
        if !(1..=4).contains(&symbol) { return -1; }
        text[i] = symbol;
    }

    let mut child = [[0usize; 5]; CW_NODES];
    let mut parent = [0usize; CW_NODES];
    let mut label = [0usize; CW_NODES];
    let mut depth = [0usize; CW_NODES];
    let mut path = [[0i64; CW_L]; CW_NODES];
    let mut terminal = [false; CW_NODES];
    let mut nodes = 1usize;
    for i in 0..p {
        let mut v = 0usize;
        for j in (0..lens[i]).rev() {
            let symbol = patterns[i][j] as usize;
            let mut encoded = child[v][symbol];
            if encoded == 0 {
                let u = nodes;
                nodes += 1;
                child[v][symbol] = u + 1;
                parent[u] = v;
                label[u] = symbol;
                depth[u] = depth[v] + 1;
                for k in 0..depth[v] { path[u][k] = path[v][k]; }
                path[u][depth[v]] = symbol as i64;
                encoded = u + 1;
            }
            v = encoded - 1;
        }
        terminal[v] = true;
    }

    let mut shift1 = [shortest; CW_NODES];
    let mut shift2 = [shortest; CW_NODES];
    let mut bad = [shortest + 1; 5];
    shift1[0] = 1;
    for v in 1..nodes {
        bad[label[v]] = bad[label[v]].min(depth[v]);
        shift2[v] = shift2[parent[v]];
        for u in 1..nodes {
            if cw_is_suffix(v, u, &depth, &path) {
                let delta = depth[u] - depth[v];
                shift1[v] = shift1[v].min(delta);
                if terminal[u] { shift2[v] = shift2[v].min(delta); }
            }
        }
    }

    let mut matches = 0i64;
    let mut position = shortest as isize - 1;
    while position < n as isize {
        let mut v = 0usize;
        let mut i = position;
        while i >= 0 {
            let symbol = text[i as usize] as usize;
            let encoded = child[v][symbol];
            if encoded == 0 { break; }
            v = encoded - 1;
            i -= 1;
            if terminal[v] { matches += 1; }
        }
        let symbol = if i >= 0 { text[i as usize] as usize } else { 0 };
        let char_shift = if symbol == 0 { shortest + 1 } else { bad[symbol] };
        let delta = shift2[v].min(shift1[v].max(char_shift.saturating_sub(depth[v] + 1)));
        position += delta as isize;
    }
    matches
}
