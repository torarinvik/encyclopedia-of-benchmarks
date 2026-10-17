const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_EDGES;

fn find_vertex(labels: &[i32; MAX_VERTICES], vertex_count: usize, label: i32) -> Option<usize> {
    (0..vertex_count).find(|&index| labels[index] == label)
}

#[no_mangle]
pub unsafe extern "C" fn kahns_algorithm(
    input_pointer: *const i64,
    length: usize,
    output_pointer: *mut u8,
    capacity: usize,
) -> i64 {
    if input_pointer.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_pointer, length) };
    let edge_count_value = input[0];
    if !(0..=MAX_EDGES as i64).contains(&edge_count_value) { return -1; }
    let edge_count = edge_count_value as usize;
    if length != 1 + 2 * edge_count { return -1; }

    let mut labels = [0i32; MAX_VERTICES];
    let mut first_edge = [-1i32; MAX_VERTICES];
    let mut tail_edge = [-1i32; MAX_VERTICES];
    let mut next_edge = [-1i32; MAX_EDGES];
    let mut to = [0usize; MAX_EDGES];
    let mut indegree = [0usize; MAX_VERTICES];
    let mut vertex_count = 0usize;
    for edge in 0..edge_count {
        let from_value = input[1 + 2 * edge];
        let to_value = input[2 + 2 * edge];
        if from_value < i32::MIN as i64 || from_value > i32::MAX as i64 ||
            to_value < i32::MIN as i64 || to_value > i32::MAX as i64 { return -1; }
        let from_label = from_value as i32;
        let to_label = to_value as i32;
        let from_index = match find_vertex(&labels, vertex_count, from_label) {
            Some(index) => index,
            None => {
                if vertex_count >= MAX_VERTICES { return -1; }
                labels[vertex_count] = from_label;
                vertex_count += 1;
                vertex_count - 1
            }
        };
        let to_index = match find_vertex(&labels, vertex_count, to_label) {
            Some(index) => index,
            None => {
                if vertex_count >= MAX_VERTICES { return -1; }
                labels[vertex_count] = to_label;
                vertex_count += 1;
                vertex_count - 1
            }
        };
        to[edge] = to_index;
        if first_edge[from_index] < 0 {
            first_edge[from_index] = edge as i32;
        } else {
            next_edge[tail_edge[from_index] as usize] = edge as i32;
        }
        tail_edge[from_index] = edge as i32;
        indegree[to_index] += 1;
    }

    let mut queue = [0usize; MAX_VERTICES];
    let mut order = [0usize; MAX_VERTICES];
    let (mut queue_head, mut queue_tail, mut order_count) = (0usize, 0usize, 0usize);
    for vertex in 0..vertex_count {
        if indegree[vertex] == 0 { queue[queue_tail] = vertex; queue_tail += 1; }
    }
    if vertex_count > 0 && queue_tail != 1 { return -1; }
    while queue_head < queue_tail {
        if queue_tail - queue_head != 1 { return -1; }
        let current = queue[queue_head];
        queue_head += 1;
        order[order_count] = current;
        order_count += 1;
        let mut outgoing = first_edge[current];
        while outgoing >= 0 {
            let edge = outgoing as usize;
            let adjacent = to[edge];
            if indegree[adjacent] == 0 { return -1; }
            indegree[adjacent] -= 1;
            if indegree[adjacent] == 0 { queue[queue_tail] = adjacent; queue_tail += 1; }
            outgoing = next_edge[edge];
        }
    }
    if order_count != vertex_count { return -1; }

    let output_bytes = 4 * order_count;
    if output_pointer.is_null() || capacity < output_bytes { return -2; }
    for index in 0..order_count {
        let bits = labels[order[index]] as u32;
        for byte in 0..4 {
            unsafe { *output_pointer.add(4 * index + byte) = (bits >> (8 * byte)) as u8; }
        }
    }
    output_bytes as i64
}
