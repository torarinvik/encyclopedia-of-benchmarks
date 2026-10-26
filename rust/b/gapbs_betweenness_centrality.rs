// Clean-room bounded Brandes profile; see package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn gapbs_betweenness_centrality(input: *const i64, length: usize) -> i64 {
    const MAX_N: usize = 8;
    if input.is_null() || !(12..=74).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n_raw, k_raw) = (values[0], values[1]);
    if !(3..=MAX_N as i64).contains(&n_raw) || k_raw < 1 || k_raw > n_raw { return -1; }
    let n = n_raw as usize;
    let k = k_raw as usize;
    if length != 2 + k + n * n { return -1; }
    let mut sources = [0usize; MAX_N];
    for i in 0..k {
        let source = values[2 + i];
        if source < 0 || source >= n_raw { return -1; }
        sources[i] = source as usize;
        for j in 0..i { if sources[j] == sources[i] { return -1; } }
    }
    let mut adjacency = [[0i64; MAX_N]; MAX_N];
    for u in 0..n { for v in 0..n {
        let edge = values[2 + k + u * n + v];
        if (edge != 0 && edge != 1) || (u == v && edge != 0) { return -1; }
        adjacency[u][v] = edge;
    }}
    for u in 0..n { for v in (u + 1)..n {
        if adjacency[u][v] != adjacency[v][u] { return -1; }
    }}

    let mut scores = [0.0f32; MAX_N];
    for si in 0..k {
        let mut depth = [-1i32; MAX_N];
        let mut queue = [0usize; MAX_N];
        let mut paths = [0.0f64; MAX_N];
        let mut delta = [0.0f32; MAX_N];
        let source = sources[si];
        depth[source] = 0; paths[source] = 1.0;
        let (mut head, mut tail) = (0usize, 1usize);
        queue[0] = source;
        while head < tail {
            let u = queue[head]; head += 1;
            for v in 0..n { if adjacency[u][v] != 0 {
                if depth[v] == -1 { depth[v] = depth[u] + 1; queue[tail] = v; tail += 1; }
                if depth[v] == depth[u] + 1 { paths[v] += paths[u]; }
            }}
        }
        let mut max_depth = 0i32;
        for v in 0..n { if depth[v] > max_depth { max_depth = depth[v]; } }
        for d in (0..=max_depth).rev() { for u in 0..n { if depth[u] == d {
            let mut delta_u = 0.0f32;
            for v in 0..n { if adjacency[u][v] != 0 && depth[v] == d + 1 {
                let one_plus = 1.0f32 + delta[v];
                let contribution = (paths[u] / paths[v]) * f64::from(one_plus);
                delta_u = (f64::from(delta_u) + contribution) as f32;
            }}
            delta[u] = delta_u;
            scores[u] = (f64::from(scores[u]) + f64::from(delta_u)) as f32;
        }}}
    }
    let mut biggest = 0.0f32;
    for v in 0..n { if scores[v] > biggest { biggest = scores[v]; } }
    if !(biggest > 0.0) { return -1; }
    let mut checksum = 0i64;
    for v in 0..n {
        let normalized = scores[v] / biggest;
        let qscore = (f64::from(normalized) * 1000.0 + 0.5) as i64;
        checksum += (v as i64 + 1) * qscore;
    }
    checksum
}
