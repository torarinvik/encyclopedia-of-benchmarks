/// BFS two-coloring for a bounded undirected graph.
const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn is_graph_bipartite(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 2 + 2 * MAX_EDGES { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let vertex_count_raw = input[0];
    let edge_count_raw = input[1];
    if !(0..=MAX_VERTICES as i64).contains(&vertex_count_raw) ||
        !(0..=MAX_EDGES as i64).contains(&edge_count_raw) ||
        length != 2 + 2 * edge_count_raw as usize { return INVALID_RESULT; }
    let vertex_count = vertex_count_raw as usize;
    let edge_count = edge_count_raw as usize;

    let mut head = [-1_i32; MAX_VERTICES];
    let mut to = [0_i32; 2 * MAX_EDGES];
    let mut next = [0_i32; 2 * MAX_EDGES];
    let mut side = [-1_i32; MAX_VERTICES];
    let mut queue = [0_i32; MAX_VERTICES];
    let mut arc_count = 0_i32;
    for edge in 0..edge_count {
        let u_raw = input[2 + 2 * edge];
        let v_raw = input[3 + 2 * edge];
        if u_raw < 1 || u_raw > vertex_count_raw || v_raw < 1 || v_raw > vertex_count_raw {
            return INVALID_RESULT;
        }
        let u = (u_raw - 1) as usize;
        let v = (v_raw - 1) as usize;
        to[arc_count as usize] = v as i32;
        next[arc_count as usize] = head[u];
        head[u] = arc_count;
        arc_count += 1;
        to[arc_count as usize] = u as i32;
        next[arc_count as usize] = head[v];
        head[v] = arc_count;
        arc_count += 1;
    }

    let mut bipartite = true;
    for start in 0..vertex_count {
        if side[start] != -1 { continue; }
        let mut queue_head = 0;
        let mut queue_tail = 1;
        queue[0] = start as i32;
        side[start] = 0;
        while queue_head < queue_tail {
            let current = queue[queue_head] as usize;
            queue_head += 1;
            let mut arc = head[current];
            while arc != -1 {
                let neighbor = to[arc as usize] as usize;
                if side[neighbor] == -1 {
                    side[neighbor] = side[current] ^ 1;
                    queue[queue_tail] = neighbor as i32;
                    queue_tail += 1;
                } else if side[neighbor] == side[current] {
                    bipartite = false;
                }
                arc = next[arc as usize];
            }
        }
    }
    if bipartite { 1 } else { 0 }
}
