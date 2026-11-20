const MAX_N: usize = 8;
const INF_DIST: u8 = 9;

struct State {
    n: usize,
    threshold: usize,
    edge: [u8; 64],
    witness: [u8; 64],
    distance: [u8; 64],
    constraints: [u16; 64],
    constraint_count: usize,
}

fn population(mut mask: u16) -> usize {
    let mut count = 0;
    while mask != 0 { count += (mask & 1) as usize; mask >>= 1; }
    count
}

fn decode(input: &[i64]) -> Option<State> {
    if input.len() < 2 || input.len() > 131 || !(2..=MAX_N as i64).contains(&input[0]) {
        return None;
    }
    let n = input[0] as usize;
    if input[1] < 2 || input[1] > n as i64 || input.len() != 2 + 2*n*n { return None; }
    let threshold = input[1] as usize;
    let mut state = State { n, threshold, edge:[0;64], witness:[0;64],
        distance:[0;64], constraints:[0;64], constraint_count:0 };
    for i in 0..n*n {
        if !(0..=1).contains(&input[2+i]) || input[2+n*n+i] < 0 || input[2+n*n+i] > n as i64 {
            return None;
        }
        state.edge[i] = input[2+i] as u8;
        state.witness[i] = input[2+n*n+i] as u8;
    }
    for i in 0..n { if state.edge[i*n+i] != 0 { return None; } }
    for i in 0..n { for j in 0..n {
        state.distance[i*n+j] = if i == j { 0 } else if state.edge[i*n+j] != 0 { 1 } else { INF_DIST };
    }}
    for k in 0..n { for i in 0..n { for j in 0..n {
        let candidate = state.distance[i*n+k] + state.distance[k*n+j];
        if candidate < state.distance[i*n+j] { state.distance[i*n+j] = candidate; }
    }}}
    for i in 0..n { for j in 0..n {
        let d = state.distance[i*n+j];
        let w = state.witness[i*n+j];
        if d >= INF_DIST { return None; }
        if d <= 1 { if w != 0 { return None; } }
        else {
            if w == 0 { return None; }
            let v = (w - 1) as usize;
            if v == i || v == j { return None; }
            let left = state.distance[i*n+v];
            let right = state.distance[v*n+j];
            if left + right != d || left >= d || right >= d { return None; }
        }
    }}
    Some(state)
}

fn subpath(state: &State, from: usize, to: usize, limit: usize, out: &mut [u8;8], offset: usize) -> usize {
    let encoded = state.witness[from*state.n+to];
    if limit == 0 || encoded == 0 { return 0; }
    let middle = (encoded - 1) as usize;
    let mut count = subpath(state, from, middle, limit-1, out, offset);
    out[offset+count] = middle as u8;
    count += 1;
    let remaining = limit-count;
    if remaining > 0 { count += subpath(state, middle, to, remaining, out, offset+count); }
    count
}

fn solve(input: &[i64]) -> i64 {
    let Some(mut state) = decode(input) else { return -1; };
    for i in 0..state.n { for j in 0..state.n {
        let mut internal = [0u8;8];
        let count = subpath(&state, i, j, state.threshold, &mut internal, 0);
        let mut mask = (1u16 << i) | (1u16 << j);
        for vertex in internal.iter().take(count) { mask |= 1u16 << *vertex; }
        let duplicate = state.constraints[..state.constraint_count].contains(&mask);
        if population(mask) >= state.threshold && !duplicate {
            let at = state.constraint_count;
            state.constraints[at] = mask;
            state.constraint_count += 1;
        }
    }}
    let mut unhit = [false;64];
    for flag in unhit.iter_mut().take(state.constraint_count) { *flag = true; }
    let mut left = state.constraint_count;
    let mut selected = 0u16;
    while left > 0 {
        let mut best_vertex = 0usize;
        let mut best_score = 0usize;
        for v in 0..state.n {
            let score = (0..state.constraint_count)
                .filter(|&c| unhit[c] && (state.constraints[c] & (1u16 << v)) != 0).count();
            if score > best_score { best_vertex = v; best_score = score; }
        }
        if best_score == 0 { return -1; }
        selected |= 1u16 << best_vertex;
        for c in 0..state.constraint_count {
            if unhit[c] && (state.constraints[c] & (1u16 << best_vertex)) != 0 {
                unhit[c] = false;
                left -= 1;
            }
        }
    }
    selected as i64
}

#[no_mangle]
pub unsafe extern "C" fn zwick_deterministic_bridging_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length > 131 { return -1; }
    if length == 0 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
