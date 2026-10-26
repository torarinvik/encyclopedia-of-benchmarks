// Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 195;
const SOURCE_INFINITY: i64 = 2_147_483_647;

#[no_mangle]
pub unsafe extern "C" fn gbbs_ss_widest_path(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let source64 = *input.add(2);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || source64 < 0 || source64 >= n64 || length != 3 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let source = source64 as usize;
    let mut edges = [(0usize, 0usize, 0i64); MAX_M];
    for edge in 0..m {
        let from = *input.add(3 + 3 * edge);
        let to = *input.add(4 + 3 * edge);
        let edge_width = *input.add(5 + 3 * edge);
        if from < 0 || from >= n64 || to < 0 || to >= n64 || !(1..=32).contains(&edge_width) { return -1; }
        edges[edge] = (from as usize, to as usize, edge_width);
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut width = [0i64; MAX_N];
    let mut settled = [false; MAX_N];
    width[source] = SOURCE_INFINITY;
    for _step in 0..n {
        let mut u = None;
        for vertex in 0..n {
            if !settled[vertex] && u.map_or(true, |best| width[vertex] > width[best]) { u = Some(vertex); }
        }
        let Some(u) = u else { break };
        if width[u] == 0 { break; }
        settled[u] = true;
        for &(from, to, edge_width) in edges[..m].iter() {
            if from != u || settled[to] { continue; }
            let candidate = width[u].min(edge_width);
            if candidate > width[to] { width[to] = candidate; }
        }
    }
    for vertex in 0..n {
        let bits = width[vertex] as u64;
        for byte in 0..8 { *output.add(8 * vertex + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
