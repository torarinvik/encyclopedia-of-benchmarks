#[no_mangle]
pub unsafe extern "C" fn incremental_minimum_spanning_forest(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=98).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=16).contains(&values[0]) || !(1..=32).contains(&values[1]) { return -1; }
    let (n, m) = (values[0] as usize, values[1] as usize);
    if length != 2 + 3 * m { return -1; }
    for i in 0..m {
        let (u, v, weight) = (values[2+3*i], values[3+3*i], values[4+3*i]);
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || !(1..=1_000_000).contains(&weight) { return -1; }
        if (0..i).any(|j| values[4+3*j] == weight) { return -1; }
    }
    let mut active = [false; 32];
    let mut answers = [0i64; 32];
    for edge in 0..m {
        let start = values[2+3*edge] as usize;
        let target = values[3+3*edge] as usize;
        if start == target { answers[edge] = edge as i64; continue; }
        let mut parent = [usize::MAX; 16];
        let mut parent_edge = [0usize; 16];
        let mut queue = [0usize; 16];
        let (mut head, mut tail) = (0, 1);
        queue[0] = start; parent[start] = start;
        while head < tail {
            let current = queue[head]; head += 1;
            for i in 0..edge {
                if !active[i] { continue; }
                let (u, v) = (values[2+3*i] as usize, values[3+3*i] as usize);
                let neighbor = if u == current { v } else if v == current { u } else { continue };
                if parent[neighbor] == usize::MAX {
                    parent[neighbor] = current; parent_edge[neighbor] = i;
                    queue[tail] = neighbor; tail += 1;
                }
            }
        }
        if parent[target] == usize::MAX { active[edge] = true; answers[edge] = -1; continue; }
        let mut node = target;
        let mut heaviest = parent_edge[node];
        while node != start {
            let i = parent_edge[node];
            if values[4+3*i] > values[4+3*heaviest] { heaviest = i; }
            node = parent[node];
        }
        if values[4+3*edge] < values[4+3*heaviest] {
            active[heaviest] = false; active[edge] = true; answers[edge] = heaviest as i64;
        } else { answers[edge] = edge as i64; }
    }
    let bytes = 8 * m;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..m {
        for (b, value) in answers[i].to_le_bytes().iter().enumerate() {
            unsafe { *output.add(8*i+b) = *value; }
        }
    }
    bytes as i64
}
