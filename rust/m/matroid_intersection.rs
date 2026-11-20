const MAX_VERTICES: usize = 10;
const MAX_EDGES: usize = 20;
const MAX_COLORS: usize = 8;

fn is_forest(input: &[i64], vertices: usize, edges: usize, edge_start: usize,
             chosen: &[bool; MAX_EDGES], removed: i64, added: i64) -> bool {
    let mut parent = [0_i64; MAX_VERTICES];
    for vertex in 0..vertices { parent[vertex] = vertex as i64; }
    for edge in 0..edges {
        if edge as i64 != added && (!chosen[edge] || edge as i64 == removed) { continue; }
        let mut a = input[edge_start + 3 * edge] as usize;
        let mut b = input[edge_start + 3 * edge + 1] as usize;
        while parent[a] as usize != a { a = parent[a] as usize; }
        while parent[b] as usize != b { b = parent[b] as usize; }
        if a == b { return false; }
        parent[b] = a as i64;
    }
    true
}

fn within_quotas(input: &[i64], colors: usize, edges: usize, edge_start: usize,
                 chosen: &[bool; MAX_EDGES], removed: i64, added: i64) -> bool {
    let mut counts = [0_i64; MAX_COLORS];
    for edge in 0..edges {
        if edge as i64 != added && (!chosen[edge] || edge as i64 == removed) { continue; }
        let color = input[edge_start + 3 * edge + 2] as usize;
        counts[color] += 1;
        if counts[color] > input[3 + color] { return false; }
    }
    true
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 4 || input.len() > 72 { return -1; }
    let vertices_value = input[0];
    let edge_value = input[1];
    let colors_value = input[2];
    if !(1..=MAX_VERTICES as i64).contains(&vertices_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
        || !(1..=MAX_COLORS as i64).contains(&colors_value) { return -1; }
    let vertices = vertices_value as usize;
    let edges = edge_value as usize;
    let colors = colors_value as usize;
    if input.len() != 3 + colors + 3 * edges { return -1; }
    if input[3..3 + colors].iter().any(|&cap| !(0..=MAX_EDGES as i64).contains(&cap)) { return -1; }
    let edge_start = 3 + colors;
    for edge in 0..edges {
        let u = input[edge_start + 3 * edge];
        let v = input[edge_start + 3 * edge + 1];
        let color = input[edge_start + 3 * edge + 2];
        if u < 0 || u >= vertices_value || v < 0 || v >= vertices_value
            || color < 0 || color >= colors_value { return -1; }
    }

    let mut chosen = [false; MAX_EDGES];
    loop {
        let mut predecessor = [-2_i64; MAX_EDGES];
        let mut queue = [0_i64; MAX_EDGES];
        let mut head = 0_usize;
        let mut tail = 0_usize;
        for edge in 0..edges {
            if !chosen[edge] && is_forest(input, vertices, edges, edge_start, &chosen, -1, edge as i64) {
                predecessor[edge] = -1;
                queue[tail] = edge as i64;
                tail += 1;
            }
        }
        let mut terminal = -1_i64;
        while head < tail && terminal < 0 {
            let current = queue[head] as usize;
            head += 1;
            if !chosen[current] {
                if within_quotas(input, colors, edges, edge_start, &chosen, -1, current as i64) {
                    terminal = current as i64;
                    break;
                }
                for inside in 0..edges {
                    if chosen[inside] && predecessor[inside] == -2
                        && within_quotas(input, colors, edges, edge_start, &chosen,
                                         inside as i64, current as i64) {
                        predecessor[inside] = current as i64;
                        queue[tail] = inside as i64;
                        tail += 1;
                    }
                }
            } else {
                for outside in 0..edges {
                    if !chosen[outside] && predecessor[outside] == -2
                        && is_forest(input, vertices, edges, edge_start, &chosen,
                                     current as i64, outside as i64) {
                        predecessor[outside] = current as i64;
                        queue[tail] = outside as i64;
                        tail += 1;
                    }
                }
            }
        }
        if terminal < 0 { break; }
        let mut node = terminal;
        while node >= 0 {
            chosen[node as usize] = !chosen[node as usize];
            node = predecessor[node as usize];
        }
    }
    chosen[..edges].iter().filter(|&&included| included).count() as i64
}

#[no_mangle]
pub unsafe extern "C" fn matroid_intersection(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 72 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    solve(values)
}
