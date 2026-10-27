const L: usize = 8;
const N: usize = 32;
const E: usize = 128;

fn put_i64(out: &mut [u8], word: usize, value: i64) {
    out[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

fn positions(order: &[[i32; N]; L], sizes: &[i32; L], layer: usize, pos: &mut [i32; N]) {
    for i in 0..sizes[layer] as usize {
        pos[order[layer][i] as usize] = i as i32;
    }
}

fn reorder(order: &mut [[i32; N]; L], sizes: &[i32; L], owner: &[i32; N],
           eu: &[i32; E], ev: &[i32; E], edges: usize, target: usize, fixed: usize,
           down: bool, pos: &mut [i32; N]) {
    positions(order, sizes, fixed, pos);
    let mut rank = [-1i32; N];
    let mut num = [0i64; N];
    let mut den = [0i64; N];
    for i in 0..sizes[target] as usize {
        rank[order[target][i] as usize] = i as i32;
    }
    for e in 0..edges {
        let u = eu[e] as usize;
        let v = ev[e] as usize;
        if down && owner[u] == fixed as i32 && owner[v] == target as i32 {
            num[v] += pos[u] as i64;
            den[v] += 1;
        } else if !down && owner[u] == target as i32 && owner[v] == fixed as i32 {
            num[u] += pos[v] as i64;
            den[u] += 1;
        }
    }
    for i in 0..sizes[target] as usize {
        let v = order[target][i] as usize;
        if den[v] == 0 {
            num[v] = rank[v] as i64;
            den[v] = 1;
        }
    }
    for i in 1..sizes[target] as usize {
        let vertex = order[target][i] as usize;
        let mut j = i;
        while j > 0 {
            let prev = order[target][j - 1] as usize;
            let left = num[vertex] * den[prev];
            let right = num[prev] * den[vertex];
            if left > right || (left == right && rank[vertex] > rank[prev]) { break; }
            order[target][j] = order[target][j - 1];
            j -= 1;
        }
        order[target][j] = vertex as i32;
    }
    positions(order, sizes, target, pos);
}

#[no_mangle]
pub unsafe extern "C" fn sugiyama_barycentric_crossing_reduction(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 299 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let layers0 = values[0];
    let limit0 = values[1];
    if !(2..=8).contains(&layers0) || !(0..=16).contains(&limit0) { return -1; }
    let layers = layers0 as usize;
    let mut order = [[0i32; N]; L];
    let mut sizes = [0i32; L];
    let mut owner = [-1i32; N];
    let mut pos = [0i32; N];
    let mut eu = [0i32; E];
    let mut ev = [0i32; E];
    let mut at = 2usize;
    let mut total = 0usize;
    for layer in 0..layers {
        if at >= length { return -1; }
        let count0 = values[at];
        at += 1;
        if !(1..=32).contains(&count0) || at + count0 as usize > length { return -1; }
        let count = count0 as usize;
        sizes[layer] = count as i32;
        total += count;
        if total > N { return -1; }
        for i in 0..count {
            let id0 = values[at];
            at += 1;
            if !(0..32).contains(&id0) { return -1; }
            let id = id0 as usize;
            if owner[id] != -1 { return -1; }
            order[layer][i] = id as i32;
            owner[id] = layer as i32;
        }
    }
    if total < 2 || at >= length { return -1; }
    let ec0 = values[at];
    at += 1;
    if !(0..=128).contains(&ec0) || at + 2 * ec0 as usize != length { return -1; }
    let edges = ec0 as usize;
    for e in 0..edges {
        let u0 = values[at + 2 * e];
        let v0 = values[at + 2 * e + 1];
        if !(0..32).contains(&u0) || !(0..32).contains(&v0) { return -1; }
        let (u, v) = (u0 as usize, v0 as usize);
        if owner[u] < 0 || owner[v] != owner[u] + 1 { return -1; }
        for j in 0..e { if eu[j] == u as i32 && ev[j] == v as i32 { return -1; } }
        eu[e] = u as i32;
        ev[e] = v as i32;
    }
    let mut sweeps = 0i64;
    for _ in 0..limit0 as usize {
        let before = order;
        for layer in 0..layers - 1 {
            reorder(&mut order, &sizes, &owner, &eu, &ev, edges, layer + 1, layer, true, &mut pos);
        }
        for layer in (0..layers - 1).rev() {
            reorder(&mut order, &sizes, &owner, &eu, &ev, edges, layer, layer + 1, false, &mut pos);
        }
        sweeps += 1;
        let changed = (0..layers).any(|l| (0..sizes[l] as usize).any(|i| before[l][i] != order[l][i]));
        if !changed { break; }
    }
    for l in 0..layers { positions(&order, &sizes, l, &mut pos); }
    let mut crossings = 0i64;
    for i in 0..edges {
        for j in i + 1..edges {
            if owner[eu[i] as usize] == owner[eu[j] as usize]
                && (pos[eu[i] as usize] - pos[eu[j] as usize])
                    * (pos[ev[i] as usize] - pos[ev[j] as usize]) < 0 {
                crossings += 1;
            }
        }
    }
    let bytes = 8 * (total + 2);
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    put_i64(dst, 0, sweeps);
    put_i64(dst, 1, crossings);
    let mut word = 2;
    for l in 0..layers {
        for i in 0..sizes[l] as usize {
            put_i64(dst, word, order[l][i] as i64);
            word += 1;
        }
    }
    bytes as i64
}
