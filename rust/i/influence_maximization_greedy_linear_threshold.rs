const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_WORLDS: usize = 8;
const WEIGHT_SCALE: i64 = 256;
const MAX_INPUT: usize = 141;

fn reachable_count(n: usize, parents: &[i32; MAX_N], seeds: u16) -> i64 {
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
        for target in 0..n {
            let bit = 1u16 << target;
            if parents[target] == source as i32 && reached & bit == 0 {
                reached |= bit;
                queue[tail] = target;
                tail += 1;
            }
        }
    }
    reached.count_ones() as i64
}

unsafe fn put_i64(output: *mut u8, word: usize, value: i64) {
    for (byte, part) in value.to_le_bytes().iter().enumerate() {
        *output.add(word * 8 + byte) = *part;
    }
}

#[no_mangle]
pub unsafe extern "C" fn influence_maximization_greedy_linear_threshold(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, m0, k0, worlds0) = (values[0], values[1], values[2], values[3]);
    if !(1..=8).contains(&n0) || !(0..=24).contains(&m0)
        || k0 < 0 || k0 > n0 || !(1..=8).contains(&worlds0)
    {
        return -1;
    }
    let (n, m, k, worlds) = (n0 as usize, m0 as usize, k0 as usize, worlds0 as usize);
    if length != 4 + 3 * m + n * worlds {
        return -1;
    }

    let mut edges = [(0usize, 0usize, 0i64); MAX_M];
    let mut incoming_sum = [0i64; MAX_N];
    for edge in 0..m {
        let (source0, target0, weight) = (
            values[4 + 3 * edge], values[5 + 3 * edge], values[6 + 3 * edge],
        );
        if source0 < 0 || source0 >= n0 || target0 < 0 || target0 >= n0
            || source0 == target0 || !(0..=WEIGHT_SCALE).contains(&weight)
        {
            return -1;
        }
        let (source, target) = (source0 as usize, target0 as usize);
        if edges[..edge].iter().any(|&(u, v, _)| u == source && v == target) {
            return -1;
        }
        incoming_sum[target] += weight;
        if incoming_sum[target] > WEIGHT_SCALE {
            return -1;
        }
        edges[edge] = (source, target, weight);
    }

    let mut draws = [[0i64; MAX_N]; MAX_WORLDS];
    let draws_start = 4 + 3 * m;
    for world in 0..worlds {
        for vertex in 0..n {
            let draw = values[draws_start + world * n + vertex];
            if !(0..WEIGHT_SCALE).contains(&draw) {
                return -1;
            }
            draws[world][vertex] = draw;
        }
    }

    let mut parents = [[-1i32; MAX_N]; MAX_WORLDS];
    for world in 0..worlds {
        for target in 0..n {
            let ticket = draws[world][target];
            let mut offset = 0i64;
            for &(source, edge_target, weight) in &edges[..m] {
                if edge_target != target {
                    continue;
                }
                if offset <= ticket && ticket < offset + weight {
                    parents[world][target] = source as i32;
                    break;
                }
                offset += weight;
            }
        }
    }

    let mut selected = 0u16;
    let mut chosen = [0i64; MAX_N];
    let mut scores = [0i64; MAX_N];
    for round in 0..k {
        let mut current = [0i64; MAX_WORLDS];
        for world in 0..worlds {
            current[world] = reachable_count(n, &parents[world], selected);
        }
        let mut best: Option<(usize, i64)> = None;
        for candidate in 0..n {
            let bit = 1u16 << candidate;
            if selected & bit != 0 {
                continue;
            }
            let mut gain = 0i64;
            for world in 0..worlds {
                gain += reachable_count(n, &parents[world], selected | bit) - current[world];
            }
            if best.map_or(true, |(_, best_gain)| gain > best_gain) {
                best = Some((candidate, gain));
            }
        }
        let Some((vertex, gain)) = best else { return -1; };
        selected |= 1u16 << vertex;
        chosen[round] = vertex as i64;
        scores[round] = gain;
    }

    let bytes = (1 + 2 * k) * 8;
    if output.is_null() || capacity < bytes {
        return -2;
    }
    put_i64(output, 0, k as i64);
    for round in 0..k {
        put_i64(output, 1 + 2 * round, chosen[round]);
        put_i64(output, 2 + 2 * round, scores[round]);
    }
    bytes as i64
}
