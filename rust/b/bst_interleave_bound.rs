const MAX_NODES: usize = 8;
const MAX_ACCESSES: usize = 16;
const MAX_INPUT: usize = 36;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn bst_interleave_bound(
    input_opt: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input_opt.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_opt, length);
    let n_raw = input[0];
    let root_raw = input[1];
    if n_raw < 1 || n_raw > MAX_NODES as i64 || root_raw < 0 || root_raw >= n_raw { return -1; }
    let n = n_raw as usize;
    let root = root_raw as usize;
    let mut left = [-1i32; MAX_NODES];
    let mut right = [-1i32; MAX_NODES];
    let mut parent = [-1i32; MAX_NODES];
    let mut parent_count = [0usize; MAX_NODES];
    let mut position = 2usize;
    for node in 0..n {
        if position + 2 > length { return -1; }
        let l = input[position]; position += 1;
        let r = input[position]; position += 1;
        if l < -1 || l >= n as i64 || r < -1 || r >= n as i64 || l == node as i64 || r == node as i64
            || (l >= 0 && l == r) { return -1; }
        left[node] = l as i32; right[node] = r as i32;
        if l >= 0 { parent_count[l as usize] += 1; parent[l as usize] = node as i32; }
        if r >= 0 { parent_count[r as usize] += 1; parent[r as usize] = node as i32; }
    }
    if parent_count[root] != 0 { return -1; }
    for node in 0..n { if node != root && parent_count[node] != 1 { return -1; } }
    if position >= length { return -1; }
    let m_raw = input[position]; position += 1;
    if m_raw < 0 || m_raw > MAX_ACCESSES as i64 || length != position + m_raw as usize { return -1; }
    let m = m_raw as usize;
    let mut accesses = [0usize; MAX_ACCESSES];
    for i in 0..m {
        let key = input[position]; position += 1;
        if key < 0 || key >= n as i64 { return -1; }
        accesses[i] = key as usize;
    }

    let mut stack = [(0usize, -1i32, n as i32); MAX_NODES];
    let mut stack_size = 1usize;
    let mut visited = [false; MAX_NODES];
    let mut visited_count = 0usize;
    stack[0] = (root, -1, n as i32);
    while stack_size > 0 {
        stack_size -= 1;
        let (node, low, high) = stack[stack_size];
        if visited[node] || node as i32 <= low || node as i32 >= high { return -1; }
        visited[node] = true; visited_count += 1;
        if left[node] >= 0 {
            stack[stack_size] = (left[node] as usize, low, node as i32); stack_size += 1;
        }
        if right[node] >= 0 {
            stack[stack_size] = (right[node] as usize, node as i32, high); stack_size += 1;
        }
    }
    if visited_count != n { return -1; }

    let mut bound = 0i64;
    for pivot in 0..n {
        let mut previous = -1i32;
        for key in accesses.iter().take(m) {
            let mut ancestor = *key as i32;
            while ancestor >= 0 && ancestor != pivot as i32 { ancestor = parent[ancestor as usize]; }
            if ancestor == pivot as i32 {
                let side = if *key <= pivot { 0 } else { 1 };
                if previous >= 0 && side != previous { bound += 1; }
                previous = side;
            }
        }
    }
    if output.is_null() || capacity < 8 { return -2; }
    store_i64_le(output, bound);
    8
}
