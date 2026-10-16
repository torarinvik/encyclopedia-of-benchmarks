const MAX_VERTICES: usize = 26;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_EDGES;

/// Return the shortest directed edge count for a bounded graph.
#[no_mangle]
pub unsafe extern "C" fn breadth_first_search_shortest_path_distance(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let (vertices_value, edges_value, source_value, target_value) =
        (values[0], values[1], values[2], values[3]);
    if !(1..=MAX_VERTICES as i64).contains(&vertices_value) ||
        !(0..=MAX_EDGES as i64).contains(&edges_value) { return -1; }
    let vertices = vertices_value as usize;
    let edges = edges_value as usize;
    if source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value ||
        length != 4 + 2 * edges { return -1; }

    let mut adjacent = [[false; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..edges {
        let from = values[4 + 2 * edge];
        let to = values[5 + 2 * edge];
        if from < 0 || from >= vertices_value || to < 0 || to >= vertices_value { return -1; }
        adjacent[from as usize][to as usize] = true;
    }

    let source = source_value as usize;
    let target = target_value as usize;
    let mut distance = [-1i64; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let (mut head, mut tail) = (0usize, 0usize);
    distance[source] = 0;
    queue[tail] = source;
    tail += 1;
    while head < tail {
        let current = queue[head];
        head += 1;
        for next in 0..vertices {
            if adjacent[current][next] && distance[next] < 0 {
                distance[next] = distance[current] + 1;
                queue[tail] = next;
                tail += 1;
            }
        }
    }
    distance[target]
}
