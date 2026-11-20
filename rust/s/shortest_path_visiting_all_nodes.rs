/// Minimum walk length covering all vertices via multi-source product BFS.
const MAX_N: usize = 10;
const MAX_STATES: usize = 10240;

#[no_mangle]
pub extern "C" fn shortest_path_visiting_all_nodes(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=93).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let m_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=45).contains(&m_value) { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    if m > n * (n - 1) / 2 || length != 2 + 2 * m { return -1; }

    let mut adjacency = [0u16; MAX_N];
    for edge in 0..m {
        let u_value = values[2 + 2 * edge];
        let v_value = values[3 + 2 * edge];
        if u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value { return -1; }
        let u = u_value as usize;
        let v = v_value as usize;
        let u_bit = 1u16 << v;
        let v_bit = 1u16 << u;
        if adjacency[u] & u_bit != 0 { return -1; }
        adjacency[u] |= u_bit;
        adjacency[v] |= v_bit;
    }

    let mut reached = 1u16;
    loop {
        let previous = reached;
        for vertex in 0..n {
            if reached & (1u16 << vertex) != 0 { reached |= adjacency[vertex]; }
        }
        if reached == previous { break; }
    }
    let full = (1u16 << n) - 1;
    if reached != full { return -1; }

    let mut distance = [-1i16; MAX_STATES];
    let mut queue = [0u16; MAX_STATES];
    let mut head = 0usize;
    let mut tail = 0usize;
    for start in 0..n {
        let state = (1usize << start) * n + start;
        distance[state] = 0;
        queue[tail] = state as u16;
        tail += 1;
    }
    while head < tail {
        let state = queue[head] as usize;
        head += 1;
        let mask = state / n;
        let vertex = state % n;
        if mask == full as usize { return distance[state] as i64; }
        for next in 0..n {
            if adjacency[vertex] & (1u16 << next) == 0 { continue; }
            let next_mask = mask | (1usize << next);
            let next_state = next_mask * n + next;
            if distance[next_state] >= 0 { continue; }
            distance[next_state] = distance[state] + 1;
            queue[tail] = next_state as u16;
            tail += 1;
        }
    }
    -1
}
