const MAX_NODES: usize = 16;
const MAX_INPUT_VALUES: usize = 2 + MAX_NODES * MAX_NODES;
const MAX_EVENTS: usize = MAX_NODES + MAX_NODES * (MAX_NODES - 1) / 2;

fn visit_node(node: usize, count: usize,
    adjacent: &[[bool; MAX_NODES]; MAX_NODES], predecessors: &[[bool; MAX_NODES]; MAX_NODES],
    visited: &mut [bool; MAX_NODES], events: &mut [[i32; 3]; MAX_EVENTS],
    event_count: &mut usize, next_order: &mut i32) -> bool {
    if *event_count >= MAX_EVENTS { return false; }
    visited[node] = true;
    events[*event_count] = [1, node as i32, *next_order];
    *event_count += 1;
    *next_order += 1;
    for child in 0..count {
        if !adjacent[node][child] || visited[child] { continue; }
        let mut all_visited = true;
        for parent in 0..count {
            if predecessors[child][parent] && !visited[parent] { all_visited = false; break; }
        }
        if all_visited {
            if !visit_node(child, count, adjacent, predecessors, visited, events, event_count, next_order) { return false; }
        } else {
            if *event_count >= MAX_EVENTS { return false; }
            events[*event_count] = [0, child as i32, -1];
            *event_count += 1;
        }
    }
    true
}

unsafe fn write_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn predecessor_constrained_dfs(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_count = values[0];
    let raw_start = values[1];
    if !(1..=MAX_NODES as i64).contains(&raw_count) || raw_start < 0 || raw_start >= raw_count { return -1; }
    let count = raw_count as usize;
    if length != 2 + count * count { return -1; }
    let mut adjacent = [[false; MAX_NODES]; MAX_NODES];
    let mut predecessors = [[false; MAX_NODES]; MAX_NODES];
    let mut indegree = [0_usize; MAX_NODES];
    for from in 0..count {
        for to in 0..count {
            let bit = values[2 + from * count + to];
            if (bit != 0 && bit != 1) || (from == to && bit != 0) { return -1; }
            if bit == 1 { adjacent[from][to] = true; predecessors[to][from] = true; indegree[to] += 1; }
        }
    }
    let mut queue = [0_usize; MAX_NODES];
    let mut head = 0;
    let mut tail = 0;
    for node in 0..count { if indegree[node] == 0 { queue[tail] = node; tail += 1; } }
    while head < tail {
        let node = queue[head]; head += 1;
        for child in 0..count {
            if adjacent[node][child] { indegree[child] -= 1; if indegree[child] == 0 { queue[tail] = child; tail += 1; } }
        }
    }
    if tail != count { return -1; }
    let mut visited = [false; MAX_NODES];
    let mut events = [[0_i32; 3]; MAX_EVENTS];
    let mut event_count = 0;
    let mut next_order = 0;
    if !visit_node(raw_start as usize, count, &adjacent, &predecessors, &mut visited,
        &mut events, &mut event_count, &mut next_order) { return -1; }
    let byte_count = 12 * event_count;
    if output.is_null() || output_capacity < byte_count { return -2; }
    for (index, event) in events[..event_count].iter().enumerate() {
        for field in 0..3 { write_i32_le(output, 12 * index + 4 * field, event[field]); }
    }
    byte_count as i64
}
