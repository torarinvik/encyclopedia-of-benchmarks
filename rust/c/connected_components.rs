const MAX_VERTICES: usize = 256;

fn visit(vertex: usize, n: usize, adjacency: &[bool; MAX_VERTICES * MAX_VERTICES], seen: &mut [bool; MAX_VERTICES]) {
    seen[vertex] = true;
    for next in 0..n {
        if adjacency[vertex * MAX_VERTICES + next] && !seen[next] {
            visit(next, n, adjacency, seen);
        }
    }
}

#[no_mangle]
pub extern "C" fn connected_components(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 1026 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=256).contains(&packed[0]) || !(0..=512).contains(&packed[1]) { return -1; }
    let n = packed[0] as usize; let m = packed[1] as usize;
    if length != 2 + 2 * m { return -1; }
    let mut adjacency = [false; MAX_VERTICES * MAX_VERTICES];
    for i in 0..m {
        let u = packed[2 + 2 * i]; let v = packed[3 + 2 * i];
        if u < 1 || u > n as i64 || v < 1 || v > n as i64 { return -1; }
        let a = (u - 1) as usize; let b = (v - 1) as usize;
        adjacency[a * MAX_VERTICES + b] = true; adjacency[b * MAX_VERTICES + a] = true;
    }
    let mut seen = [false; MAX_VERTICES];
    let mut components = 0i64;
    for i in 0..n {
        if !seen[i] { visit(i, n, &adjacency, &mut seen); components += 1; }
    }
    components
}
