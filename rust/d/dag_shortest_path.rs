const MAX_VERTICES: usize = 12;
const MAX_EDGES: usize = 66;
const MAX_LENGTH: usize = 203;
const DISTANCE_OFFSET: i64 = 100_000;
const INFINITY_DISTANCE: i64 = 1_i64 << 60;

#[no_mangle]
pub unsafe extern "C" fn dag_shortest_path(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=MAX_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_VERTICES as i64).contains(&values[0]) || !(0..=MAX_EDGES as i64).contains(&values[1]) { return -1; }
    let vertex_count = values[0] as usize;
    let edge_count = values[1] as usize;
    if length != 4 + 3 * edge_count || !(0..vertex_count as i64).contains(&values[2]) || !(0..vertex_count as i64).contains(&values[3]) { return -1; }
    let mut from = [0_i64; MAX_EDGES];
    let mut to = [0_i64; MAX_EDGES];
    let mut weight = [0_i64; MAX_EDGES];
    let mut indegree = [0_i64; MAX_VERTICES];
    for edge in 0..edge_count {
        let start = values[4 + 3 * edge];
        let finish = values[5 + 3 * edge];
        let cost = values[6 + 3 * edge];
        if !(0..vertex_count as i64).contains(&start) || !(0..vertex_count as i64).contains(&finish)
            || start == finish || !(-1000..=1000).contains(&cost) { return -1; }
        if (0..edge).any(|previous| from[previous] == start && to[previous] == finish) { return -1; }
        from[edge] = start;
        to[edge] = finish;
        weight[edge] = cost;
        indegree[finish as usize] += 1;
    }
    let mut queue = [0_usize; MAX_VERTICES];
    let mut order = [0_usize; MAX_VERTICES];
    let (mut head, mut tail, mut order_count) = (0, 0, 0);
    for vertex in 0..vertex_count {
        if indegree[vertex] == 0 { queue[tail] = vertex; tail += 1; }
    }
    while head < tail {
        let vertex = queue[head]; head += 1;
        order[order_count] = vertex; order_count += 1;
        for edge in 0..edge_count {
            if from[edge] == vertex as i64 {
                let finish = to[edge] as usize;
                indegree[finish] -= 1;
                if indegree[finish] == 0 { queue[tail] = finish; tail += 1; }
            }
        }
    }
    if order_count != vertex_count { return -1; }
    let mut distance = [INFINITY_DISTANCE; MAX_VERTICES];
    distance[values[2] as usize] = 0;
    for &vertex in &order[..vertex_count] {
        if distance[vertex] == INFINITY_DISTANCE { continue; }
        for edge in 0..edge_count {
            if from[edge] == vertex as i64 {
                let finish = to[edge] as usize;
                let candidate = distance[vertex] + weight[edge];
                if candidate < distance[finish] { distance[finish] = candidate; }
            }
        }
    }
    let answer = distance[values[3] as usize];
    if answer == INFINITY_DISTANCE { 0 } else { DISTANCE_OFFSET + answer }
}
