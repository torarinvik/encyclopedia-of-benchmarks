#[no_mangle]
pub unsafe extern "C" fn directed_girth_bfs(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=131).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=16).contains(&values[0]) || !(0..=64).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2*m { return -1; }
    let mut outgoing = [0u32; 16];
    for edge in values[2..].chunks_exact(2) {
        if edge[0] < 0 || edge[1] < 0 || edge[0] >= n as i64 || edge[1] >= n as i64 { return -1; }
        outgoing[edge[0] as usize] |= 1u32 << (edge[1] as usize);
    }
    let mut best = 17;
    for start in 0..n {
        let mut distance = [-1i64; 16];
        let mut queue = [0usize; 16];
        let (mut head, mut tail) = (0, 1);
        distance[start] = 0; queue[0] = start;
        while head < tail {
            let u = queue[head]; head += 1;
            for v in 0..n {
                if outgoing[u] & (1u32 << v) == 0 { continue; }
                if v == start { best = best.min(distance[u] + 1); }
                else if distance[v] < 0 {
                    distance[v] = distance[u] + 1; queue[tail] = v; tail += 1;
                }
            }
        }
    }
    if best == 17 { 0 } else { best }
}
