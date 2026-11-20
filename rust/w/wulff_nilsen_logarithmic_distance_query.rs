use std::ptr;

const K: usize = 16;
const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 167;
const MAX_NODES: usize = 31;
const LOG_K: i32 = 4;
const INF: i64 = i64::MAX / 4;

#[derive(Clone, Copy)]
struct Split {
    low: i32,
    high: i32,
    middle: i32,
    gap: i32,
    left: i32,
    right: i32,
}

impl Split {
    const EMPTY: Self = Self { low: 0, high: 0, middle: -1, gap: -1, left: -1, right: -1 };
}

struct State {
    distance: [[i64; MAX_N]; MAX_N],
    nearest: [[u8; MAX_N]; K],
    bunch: [[bool; MAX_N]; MAX_N],
    trees: [[Split; MAX_NODES]; MAX_N],
    counts: [usize; MAX_N],
}

impl State {
    fn new() -> Self {
        Self {
            distance: [[INF; MAX_N]; MAX_N],
            nearest: [[0; MAX_N]; K],
            bunch: [[false; MAX_N]; MAX_N],
            trees: [[Split::EMPTY; MAX_NODES]; MAX_N],
            counts: [0; MAX_N],
        }
    }
}

fn midpoint(low: i32, high: i32) -> i32 {
    let mut chosen = -1;
    let mut best = i32::MAX;
    let mut candidate = low + 2;
    while candidate <= high - 2 {
        let gap = (2 * candidate - low - high).abs();
        if gap < best {
            best = gap;
            chosen = candidate;
        }
        candidate += 2;
    }
    chosen
}

fn build_tree(state: &mut State, source: usize, low: i32, high: i32, n: usize) -> i32 {
    let index = state.counts[source];
    if index >= MAX_NODES { return -1; }
    state.counts[source] += 1;
    state.trees[source][index] = Split { low, high, middle: -1, gap: -1, left: -1, right: -1 };
    if high - low <= LOG_K { return index as i32; }

    let middle = midpoint(low, high);
    if middle < 0 { return -1; }
    let mut selected = low;
    let mut best_delta = state.distance[source][state.nearest[(low + 2) as usize][source] as usize]
        - state.distance[source][state.nearest[low as usize][source] as usize];
    let mut level = low + 2;
    while level <= middle - 2 {
        let delta = state.distance[source][state.nearest[(level + 2) as usize][source] as usize]
            - state.distance[source][state.nearest[level as usize][source] as usize];
        if delta > best_delta {
            best_delta = delta;
            selected = level;
        }
        level += 2;
    }
    state.trees[source][index].middle = middle;
    state.trees[source][index].gap = selected;
    let left = build_tree(state, source, low, selected, n);
    let right = build_tree(state, source, middle, high, n);
    if left < 0 || right < 0 { return -1; }
    state.trees[source][index].left = left;
    state.trees[source][index].right = right;
    index as i32
}

fn dist_k(state: &State, n: usize, mut source: usize, mut target: usize,
          start: usize, probes: &mut i64) -> Option<i64> {
    let mut level = start;
    loop {
        let pivot = state.nearest[level][source] as usize;
        *probes += 1;
        if state.bunch[target][pivot] {
            return Some(state.distance[source][pivot] + state.distance[target][pivot]);
        }
        if level + 1 >= K { return None; }
        std::mem::swap(&mut source, &mut target);
        level += 1;
        if source >= n { return None; }
    }
}

fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), bytes.len()); }
}

#[no_mangle]
pub unsafe extern "C" fn wulff_nilsen_logarithmic_distance_query(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 18 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_raw, m_raw) = (values[0], values[1]);
    if n_raw < 1 || n_raw as usize > MAX_N || m_raw < 0 || m_raw as usize > MAX_M { return -1; }
    let n = n_raw as usize;
    let m = m_raw as usize;
    let vertex_bits = (1i64 << n) - 1;
    let mut layers = [0u64; K];
    for level in 1..K {
        let raw = values[1 + level];
        if raw <= 0 || raw & !vertex_bits != 0 { return -1; }
        layers[level] = raw as u64;
        if level > 1 && layers[level] & !layers[level - 1] != 0 { return -1; }
    }
    let query_at = 17 + 3 * m;
    if query_at >= length { return -1; }
    let q_raw = values[query_at];
    if q_raw < 0 || q_raw as usize > MAX_Q || length != query_at + 1 + 2 * q_raw as usize { return -1; }
    let q = q_raw as usize;

    let mut state = State::new();
    for vertex in 0..n { state.distance[vertex][vertex] = 0; }
    let mut previous = None;
    for edge in 0..m {
        let offset = 17 + 3 * edge;
        let (u_raw, v_raw, weight) = (values[offset], values[offset + 1], values[offset + 2]);
        if u_raw < 0 || v_raw <= u_raw || v_raw as usize >= n || !(1..=1000).contains(&weight) { return -1; }
        let (u, v) = (u_raw as usize, v_raw as usize);
        if previous.map_or(false, |pair| (u, v) <= pair) { return -1; }
        previous = Some((u, v));
        state.distance[u][v] = weight;
        state.distance[v][u] = weight;
    }
    for via in 0..n {
        for from in 0..n {
            for to in 0..n {
                let candidate = state.distance[from][via] + state.distance[via][to];
                if candidate < state.distance[from][to] { state.distance[from][to] = candidate; }
            }
        }
    }
    if (0..n).any(|i| (0..n).any(|j| state.distance[i][j] == INF)) { return -1; }

    for vertex in 0..n { state.nearest[0][vertex] = vertex as u8; }
    for level in 1..K {
        for vertex in 0..n {
            let mut best: Option<usize> = None;
            for candidate in 0..n {
                if layers[level] >> candidate & 1 == 0 { continue; }
                if best.map_or(true, |prior| state.distance[vertex][candidate] < state.distance[vertex][prior]
                    || (state.distance[vertex][candidate] == state.distance[vertex][prior] && candidate < prior)) {
                    best = Some(candidate);
                }
            }
            match best {
                Some(chosen) => state.nearest[level][vertex] = chosen as u8,
                None => return -1,
            }
        }
    }

    for center in 0..n {
        for level in 0..K {
            let current = if level == 0 { vertex_bits as u64 } else { layers[level] };
            let following = if level + 1 == K { 0 } else { layers[level + 1] };
            let mut next_distance = INF;
            for candidate in 0..n {
                if following >> candidate & 1 != 0 {
                    next_distance = next_distance.min(state.distance[center][candidate]);
                }
            }
            for candidate in 0..n {
                if current >> candidate & 1 != 0 && following >> candidate & 1 == 0
                    && state.distance[center][candidate] < next_distance {
                    state.bunch[center][candidate] = true;
                }
            }
        }
    }
    for source in 0..n {
        if build_tree(&mut state, source, 0, (K - 1) as i32, n) < 0 { return -1; }
    }

    let mut staged = [0i64; 1 + 2 * MAX_Q];
    staged[0] = q as i64;
    for query in 0..q {
        let offset = query_at + 1 + 2 * query;
        let (source_raw, target_raw) = (values[offset], values[offset + 1]);
        if source_raw < 0 || source_raw as usize >= n || target_raw < 0 || target_raw as usize >= n { return -1; }
        let (source, target) = (source_raw as usize, target_raw as usize);
        if source == target {
            staged[1 + 2 * query] = 0;
            staged[2 + 2 * query] = 0;
            continue;
        }
        let mut node_id = 0usize;
        let mut probes = 0i64;
        while state.trees[source][node_id].high - state.trees[source][node_id].low > LOG_K {
            let node = state.trees[source][node_id];
            let first = state.bunch[target][state.nearest[node.gap as usize][source] as usize];
            let second = state.bunch[source][state.nearest[node.gap as usize + 1][target] as usize];
            probes += 2;
            node_id = if !first && !second { node.right as usize } else { node.left as usize };
        }
        let start = state.trees[source][node_id].low as usize;
        let estimate = match dist_k(&state, n, source, target, start, &mut probes) {
            Some(value) => value,
            None => return -1,
        };
        staged[1 + 2 * query] = estimate;
        staged[2 + 2 * query] = probes;
    }

    let words = 1 + 2 * q;
    let bytes = 8 * words;
    if output.is_null() || capacity < bytes { return -2; }
    for (index, value) in staged[..words].iter().enumerate() { put_i64(output, index * 8, *value); }
    bytes as i64
}
