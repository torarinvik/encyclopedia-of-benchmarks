const MAX_N: usize = 32;
const MAX_M: usize = 128;
const MAX_INPUT: usize = 259;
const MAX_ARCS: usize = 2 * MAX_M;

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > MAX_INPUT { return -1; }
    let n_value = input[0];
    let m_value = input[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_M as i64).contains(&m_value) { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    if input.len() != 2 + 2 * m { return -1; }

    let mut edge_seen = [[false; MAX_N]; MAX_N];
    let mut head = [-1i32; MAX_N];
    let mut arc_to = [0i32; MAX_ARCS];
    let mut arc_edge = [0i32; MAX_ARCS];
    let mut next_arc = [0i32; MAX_ARCS];
    let mut arc_count = 0usize;
    for e in 0..m {
        let u_value = input[2 + 2 * e];
        let v_value = input[3 + 2 * e];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1; }
        let u = u_value as usize;
        let v = v_value as usize;
        if edge_seen[u][v] { return -1; }
        edge_seen[u][v] = true;
        edge_seen[v][u] = true;
        arc_to[arc_count] = v as i32; arc_edge[arc_count] = e as i32;
        next_arc[arc_count] = head[u]; head[u] = arc_count as i32; arc_count += 1;
        arc_to[arc_count] = u as i32; arc_edge[arc_count] = e as i32;
        next_arc[arc_count] = head[v]; head[v] = arc_count as i32; arc_count += 1;
    }

    let mut state = [0i32; MAX_N];
    let mut parent = [-1i32; MAX_N];
    let mut parent_edge = [-1i32; MAX_N];
    let mut depth = [0i32; MAX_N];
    let mut cursor = [-1i32; MAX_N];
    let mut stack = [0i32; MAX_N];
    let mut cycle_of = [-1i32; MAX_M];
    let mut used = [false; MAX_M];
    let mut cycle_vertices = [0i32; MAX_N];
    let mut cycles = 0i32;
    let mut edge_cactus = true;
    let mut vertex_cactus = true;
    for root in 0..n {
        if !edge_cactus { break; }
        if state[root] != 0 { continue; }
        let mut top = 1usize;
        state[root] = 1; cursor[root] = head[root]; stack[0] = root as i32;
        while top > 0 && edge_cactus {
            let u = stack[top - 1] as usize;
            let arc = cursor[u];
            if arc < 0 { state[u] = 2; top -= 1; continue; }
            cursor[u] = next_arc[arc as usize];
            let e = arc_edge[arc as usize] as usize;
            if used[e] { continue; }
            used[e] = true;
            let v = arc_to[arc as usize] as usize;
            if state[v] == 0 {
                parent[v] = u as i32; parent_edge[v] = e as i32; depth[v] = depth[u] + 1;
                state[v] = 1; cursor[v] = head[v]; stack[top] = v as i32; top += 1;
            } else if state[v] == 1 && depth[v] < depth[u] {
                let mut x = u;
                while x != v {
                    let tree_edge = parent_edge[x] as usize;
                    if parent_edge[x] < 0 || cycle_of[tree_edge] != -1 { edge_cactus = false; break; }
                    x = parent[x] as usize;
                }
                if !edge_cactus { break; }
                let mut x = u;
                cycle_vertices[x] += 1;
                if cycle_vertices[x] > 1 { vertex_cactus = false; }
                while x != v {
                    let tree_edge = parent_edge[x] as usize;
                    cycle_of[tree_edge] = cycles;
                    x = parent[x] as usize;
                    cycle_vertices[x] += 1;
                    if cycle_vertices[x] > 1 { vertex_cactus = false; }
                }
                cycle_of[e] = cycles;
                cycles += 1;
            }
        }
    }
    if !edge_cactus { return 0; }
    4 * (cycles as i64) + (if vertex_cactus { 2 } else { 0 }) + 1
}

#[no_mangle]
pub unsafe extern "C" fn cactus_graph_recognition(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
