const MAX_N: usize = 32;
const SIDE: usize = MAX_N + 1;
const MAX_INPUT: usize = 531;
const MAX_FRAMES: usize = 64;
const INF: i64 = i64::MAX / 4;

#[derive(Clone, Copy, Default)]
struct Frame { row_begin: usize, row_end: usize, col_begin: usize, col_end: usize }

fn monge_layer(n: usize, layer: usize, dp: &[i64; SIDE], cost: &[i64; SIDE * SIDE],
               next: &mut [i64; SIDE]) {
    let mut stack = [Frame::default(); MAX_FRAMES];
    let mut stack_size = 1usize;
    stack[0] = Frame { row_begin: layer, row_end: n + 1, col_begin: layer - 1, col_end: n };
    while stack_size != 0 {
        stack_size -= 1;
        let frame = stack[stack_size];
        if frame.row_begin >= frame.row_end { continue; }
        let row = (frame.row_begin + frame.row_end) / 2;
        let upper = frame.col_end.min(row);
        let mut best_column = frame.col_begin;
        let mut best_value = INF;
        for column in frame.col_begin..upper {
            if dp[column] == INF { continue; }
            let candidate = dp[column] + cost[column * SIDE + row];
            if candidate < best_value { best_value = candidate; best_column = column; }
        }
        next[row] = best_value;
        if row + 1 < frame.row_end && best_column < frame.col_end {
            stack[stack_size] = Frame { row_begin: row + 1, row_end: frame.row_end,
                col_begin: best_column, col_end: frame.col_end };
            stack_size += 1;
        }
        if frame.row_begin < row && frame.col_begin < best_column + 1 {
            stack[stack_size] = Frame { row_begin: frame.row_begin, row_end: row,
                col_begin: frame.col_begin, col_end: best_column + 1 };
            stack_size += 1;
        }
    }
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 2 || values.len() > MAX_INPUT { return -1; }
    if values[0] < 1 || values[0] > MAX_N as i64 || values[1] < 1 || values[1] > values[0] { return -1; }
    let n = values[0] as usize;
    let layers = values[1] as usize;
    if values.len() != 2 + n * (n + 1) / 2 { return -1; }

    let mut cost = [0i64; SIDE * SIDE];
    let mut offset = 2usize;
    for u in 0..n {
        for v in (u + 1)..=n {
            let weight = values[offset];
            offset += 1;
            if !(0..=1_000_000).contains(&weight) { return -1; }
            cost[u * SIDE + v] = weight;
        }
    }
    for u in 0..n.saturating_sub(1) {
        for v in (u + 2)..n {
            if cost[u * SIDE + v] + cost[(u + 1) * SIDE + v + 1]
                > cost[u * SIDE + v + 1] + cost[(u + 1) * SIDE + v] { return -1; }
        }
    }
    let mut dp = [INF; SIDE];
    dp[0] = 0;
    for layer in 1..=layers {
        let mut next = [INF; SIDE];
        monge_layer(n, layer, &dp, &cost, &mut next);
        dp = next;
    }
    dp[n]
}

#[no_mangle]
pub unsafe extern "C" fn monge_dag_fixed_edge_shortest_path(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
