const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_WORLDS: usize = 8;

fn reachable_count(n: usize, world: usize, seeds: u16,
                   edges: &[(usize, usize, u8)]) -> i64 {
    let mut reached = seeds;
    let mut queue = [0usize; MAX_N];
    let mut head = 0usize;
    let mut tail = 0usize;
    for vertex in 0..n {
        if seeds & (1u16 << vertex) != 0 {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    while head < tail {
        let source = queue[head];
        head += 1;
        for &(edge_source, target, worlds) in edges {
            let bit = 1u16 << target;
            if edge_source == source && worlds & (1u8 << world) != 0 && reached & bit == 0 {
                reached |= bit;
                queue[tail] = target;
                tail += 1;
            }
        }
    }
    reached.count_ones() as i64
}

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn influence_maximization_greedy_live_edge(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=77).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, m0, k0, worlds0) = (values[0], values[1], values[2], values[3]);
    if !(1..=8).contains(&n0) || !(0..=24).contains(&m0)
        || k0 < 0 || k0 > n0 || !(1..=8).contains(&worlds0)
        || length != 4 + 3 * m0 as usize
    {
        return -1;
    }
    let (n, m, k, worlds) = (n0 as usize, m0 as usize, k0 as usize, worlds0 as usize);
    let allowed = (1i64 << worlds) - 1;
    let mut edges = Vec::with_capacity(m);
    for edge in 0..m {
        let (u0, v0, mask0) = (values[4 + 3 * edge], values[5 + 3 * edge], values[6 + 3 * edge]);
        if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0
            || mask0 < 0 || mask0 > allowed
        {
            return -1;
        }
        let (u, v) = (u0 as usize, v0 as usize);
        if edges.iter().any(|&(a, b, _)| a == u && b == v) {
            return -1;
        }
        edges.push((u, v, mask0 as u8));
    }

    let mut selected = 0u16;
    let mut chosen = [0i64; MAX_N];
    let mut scores = [0i64; MAX_N];
    for round in 0..k {
        let mut current = [0i64; MAX_WORLDS];
        for world in 0..worlds {
            current[world] = reachable_count(n, world, selected, &edges);
        }
        let mut best: Option<(usize, i64)> = None;
        for candidate in 0..n {
            let bit = 1u16 << candidate;
            if selected & bit != 0 {
                continue;
            }
            let mut score = 0i64;
            for world in 0..worlds {
                score += reachable_count(n, world, selected | bit, &edges) - current[world];
            }
            if best.map_or(true, |(_, best_score)| score > best_score) {
                best = Some((candidate, score));
            }
        }
        let Some((vertex, score)) = best else { return -1; };
        selected |= 1u16 << vertex;
        chosen[round] = vertex as i64;
        scores[round] = score;
    }

    let bytes = (1 + 2 * k) * 8;
    if output.is_null() || capacity < bytes {
        return -2;
    }
    let out = std::slice::from_raw_parts_mut(output, bytes);
    put_i64(out, 0, k as i64);
    for round in 0..k {
        put_i64(out, 1 + 2 * round, chosen[round]);
        put_i64(out, 2 + 2 * round, scores[round]);
    }
    bytes as i64
}
