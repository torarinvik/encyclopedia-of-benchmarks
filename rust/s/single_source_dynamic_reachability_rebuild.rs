const MAX_N: usize = 8;
const MAX_INITIAL_EDGES: usize = 16;
const MAX_OPERATIONS: usize = 20;
const MAX_OUTPUT_BYTES: usize = 168;

fn rebuild_reachable(n: usize, source: usize, adjacency: &[[bool; MAX_N]; MAX_N], reachable: &mut [bool; MAX_N]) {
    *reachable = [false; MAX_N];
    let mut queue = [0usize; MAX_N];
    let mut head = 0usize;
    let mut tail = 0usize;
    reachable[source] = true;
    queue[tail] = source; tail += 1;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..n {
            if adjacency[u][v] && !reachable[v] {
                reachable[v] = true;
                queue[tail] = v; tail += 1;
            }
        }
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn single_source_dynamic_reachability_rebuild(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 97 { return -1; }
    let n_raw = *input;
    let source_raw = *input.add(1);
    let edge_count_raw = *input.add(2);
    if n_raw < 2 || n_raw > MAX_N as i64 || source_raw < 0 || source_raw >= n_raw ||
            edge_count_raw < 0 || edge_count_raw > MAX_INITIAL_EDGES as i64 { return -1; }
    let n = n_raw as usize;
    let source = source_raw as usize;
    let edge_count = edge_count_raw as usize;
    let operation_count_offset = 3 + 2 * edge_count;
    if length <= operation_count_offset { return -1; }
    let operation_count_raw = *input.add(operation_count_offset);
    if operation_count_raw < 0 || operation_count_raw > MAX_OPERATIONS as i64 ||
            length != operation_count_offset + 1 + 3 * operation_count_raw as usize { return -1; }
    let operation_count = operation_count_raw as usize;

    let mut adjacency = [[false; MAX_N]; MAX_N];
    let mut cursor = 3usize;
    for _ in 0..edge_count {
        let u_raw = *input.add(cursor); let v_raw = *input.add(cursor + 1); cursor += 2;
        if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw { return -1; }
        let u = u_raw as usize; let v = v_raw as usize;
        if adjacency[u][v] { return -1; }
        adjacency[u][v] = true;
    }
    cursor = operation_count_offset + 1;
    let mut op_type = [0i32; MAX_OPERATIONS];
    let mut op_u = [0usize; MAX_OPERATIONS];
    let mut op_v = [0usize; MAX_OPERATIONS];
    let mut query_count = 0usize;
    for i in 0..operation_count {
        let kind = *input.add(cursor); let u = *input.add(cursor + 1); let v = *input.add(cursor + 2); cursor += 3;
        if kind == 0 || kind == 1 {
            if u < 0 || u >= n_raw || v < 0 || v >= n_raw { return -1; }
        } else if kind == 2 {
            if u < 0 || u >= n_raw || v != 0 { return -1; }
            query_count += 1;
        } else { return -1; }
        op_type[i] = kind as i32; op_u[i] = u as usize; op_v[i] = v as usize;
    }

    let output_bytes = 8 * (1 + query_count);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut reachable = [false; MAX_N];
    let mut answers = [0i64; MAX_OPERATIONS];
    let mut answer_count = 0usize;
    rebuild_reachable(n, source, &adjacency, &mut reachable);
    for i in 0..operation_count {
        if op_type[i] == 0 {
            adjacency[op_u[i]][op_v[i]] = true;
            rebuild_reachable(n, source, &adjacency, &mut reachable);
        } else if op_type[i] == 1 {
            adjacency[op_u[i]][op_v[i]] = false;
            rebuild_reachable(n, source, &adjacency, &mut reachable);
        } else {
            answers[answer_count] = if reachable[op_u[i]] { 1 } else { 0 };
            answer_count += 1;
        }
    }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, answer_count as i64);
    for i in 0..answer_count { store_i64_le(staged.as_mut_ptr(), 8 * (i + 1), answers[i]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
