const NMAX: usize = 8;
const MMAX: usize = 24;
const INPUT_MAX: usize = 4 + 3 * MMAX + 1;

struct State {
    n: usize,
    sink: usize,
    residual: [[i64; NMAX]; NMAX],
    distance: [i64; NMAX],
    gap: [i64; NMAX + 1],
    current: [usize; NMAX],
    stopped: bool,
}

fn dfs(state: &mut State, u: usize, amount: i64) -> i64 {
    if u == state.sink { return amount; }
    while state.current[u] < state.n {
        let v = state.current[u];
        if state.residual[u][v] > 0 && state.distance[u] == state.distance[v] + 1 {
            let sent = dfs(state, v, amount.min(state.residual[u][v]));
            if sent > 0 {
                state.residual[u][v] -= sent;
                state.residual[v][u] += sent;
                return sent;
            }
            if state.stopped { return 0; }
        }
        state.current[u] += 1;
    }
    let old = state.distance[u];
    let mut best = state.n as i64;
    for v in 0..state.n {
        if state.residual[u][v] > 0 { best = best.min(state.distance[v]); }
    }
    let replacement = (best + 1).min(state.n as i64);
    state.gap[old as usize] -= 1;
    state.distance[u] = replacement;
    state.gap[replacement as usize] += 1;
    state.current[u] = 0;
    if old < state.n as i64 && state.gap[old as usize] == 0 { state.stopped = true; }
    0
}

#[no_mangle]
pub unsafe extern "C" fn isap_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > INPUT_MAX { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let source64 = *input.add(2);
    let sink64 = *input.add(3);
    if !(2..=NMAX as i64).contains(&n64) || !(0..=MMAX as i64).contains(&m64) ||
        source64 < 0 || source64 >= n64 || sink64 < 0 || sink64 >= n64 || source64 == sink64 ||
        length != 4 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let source = source64 as usize;
    let sink = sink64 as usize;
    let mut state = State { n, sink, residual: [[0; NMAX]; NMAX], distance: [0; NMAX],
        gap: [0; NMAX + 1], current: [0; NMAX], stopped: false };
    for e in 0..m64 as usize {
        let u = *input.add(4 + 3 * e);
        let v = *input.add(5 + 3 * e);
        let capacity = *input.add(6 + 3 * e);
        if u < 0 || u >= n64 || v < 0 || v >= n64 || u == v || !(0..=100).contains(&capacity) { return -1; }
        state.residual[u as usize][v as usize] += capacity;
    }
    for v in 0..n { state.distance[v] = n as i64; }
    state.distance[sink] = 0;
    let mut queue = [0usize; NMAX];
    let (mut head, mut tail) = (0usize, 1usize);
    queue[0] = sink;
    while head < tail {
        let v = queue[head]; head += 1;
        for p in 0..n {
            if state.distance[p] == n as i64 && state.residual[p][v] > 0 {
                state.distance[p] = state.distance[v] + 1;
                queue[tail] = p; tail += 1;
            }
        }
    }
    if state.distance[source] >= n as i64 { return 0; }
    for v in 0..n { state.gap[state.distance[v] as usize] += 1; }
    let mut flow = 0i64;
    while state.distance[source] < n as i64 && !state.stopped { flow += dfs(&mut state, source, 2400); }
    flow
}
