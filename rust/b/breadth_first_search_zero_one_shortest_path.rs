const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + 3 * MAX_EDGES;
const MAX_DEQUE_CAPACITY: usize = MAX_VERTICES * MAX_VERTICES + 1;

#[no_mangle]
pub unsafe extern "C" fn breadth_first_search_zero_one_shortest_path(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -2; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let (vertex_value, edge_value, start_value, finish_value) = (values[0], values[1], values[2], values[3]);
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value) || !(0..=MAX_EDGES as i64).contains(&edge_value) { return -2; }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    if length != 4 + 3 * edges || start_value < 0 || start_value >= vertices as i64 || finish_value < 0 || finish_value >= vertices as i64 { return -2; }
    let mut edge_to = [0usize; MAX_EDGES];
    let mut edge_weight = [0i64; MAX_EDGES];
    let mut next_edge = [-1isize; MAX_EDGES];
    let mut head_edge = [-1isize; MAX_VERTICES];
    let mut tail_edge = [-1isize; MAX_VERTICES];
    for edge in 0..edges {
        let from = values[4 + 3 * edge];
        let to = values[5 + 3 * edge];
        let weight = values[6 + 3 * edge];
        if from < 0 || from >= vertices as i64 || to < 0 || to >= vertices as i64 || (weight != 0 && weight != 1) { return -2; }
        edge_to[edge] = to as usize;
        edge_weight[edge] = weight;
        let source = from as usize;
        if head_edge[source] < 0 { head_edge[source] = edge as isize; }
        else { next_edge[tail_edge[source] as usize] = edge as isize; }
        tail_edge[source] = edge as isize;
    }
    let start = start_value as usize;
    let finish = finish_value as usize;
    let mut distance = [i64::MAX; MAX_VERTICES];
    let mut deque = [0usize; MAX_DEQUE_CAPACITY];
    let (mut deque_head, mut deque_count) = (0usize, 1usize);
    distance[start] = 0;
    deque[0] = start;
    while deque_count > 0 {
        let node = deque[deque_head];
        deque_head = (deque_head + 1) % MAX_DEQUE_CAPACITY;
        deque_count -= 1;
        let mut edge = head_edge[node];
        while edge >= 0 {
            let edge_index = edge as usize;
            let neighbor = edge_to[edge_index];
            let candidate = distance[node] + edge_weight[edge_index];
            if candidate < distance[neighbor] {
                distance[neighbor] = candidate;
                if edge_weight[edge_index] == 0 {
                    deque_head = (deque_head + MAX_DEQUE_CAPACITY - 1) % MAX_DEQUE_CAPACITY;
                    deque[deque_head] = neighbor;
                } else {
                    deque[(deque_head + deque_count) % MAX_DEQUE_CAPACITY] = neighbor;
                }
                deque_count += 1;
            }
            edge = next_edge[edge_index];
        }
    }
    if distance[finish] == i64::MAX { -1 } else { distance[finish] }
}
