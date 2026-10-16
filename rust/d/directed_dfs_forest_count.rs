const MAX_EDGE_COUNT: usize = 64;
const MAX_VERTEX_ID: i64 = 63;
const MAX_NODE_COUNT: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_EDGE_COUNT;

fn find_last_node(label: i64, labels: &[i64; MAX_NODE_COUNT], node_count: usize) -> usize {
    let mut found = MAX_NODE_COUNT;
    for node in 0..node_count {
        if labels[node] == label { found = node; }
    }
    found
}

fn visit(current: usize, edge_count: usize, edge_starts: &[usize; MAX_EDGE_COUNT],
    edge_ends: &[usize; MAX_EDGE_COUNT], visited: &mut [bool; MAX_NODE_COUNT]) {
    visited[current] = true;
    for edge in 0..edge_count {
        let destination = edge_ends[edge];
        if edge_starts[edge] == current && !visited[destination] {
            visit(destination, edge_count, edge_starts, edge_ends, visited);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn directed_dfs_forest_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let edge_count_value = values[0];
    if !(0..=MAX_EDGE_COUNT as i64).contains(&edge_count_value) { return -1; }
    let edge_count = edge_count_value as usize;
    if length != 1 + 2 * edge_count { return -1; }

    let mut labels = [0_i64; MAX_NODE_COUNT];
    let mut edge_starts = [0_usize; MAX_EDGE_COUNT];
    let mut edge_ends = [0_usize; MAX_EDGE_COUNT];
    let mut node_count = 0;
    for edge in 0..edge_count {
        let start_label = values[1 + 2 * edge];
        let end_label = values[2 + 2 * edge];
        if !(0..=MAX_VERTEX_ID).contains(&start_label)
            || !(0..=MAX_VERTEX_ID).contains(&end_label) { return -1; }

        let mut start = find_last_node(start_label, &labels, node_count);
        let end;
        if start_label == end_label {
            if start == MAX_NODE_COUNT {
                start = node_count;
                labels[node_count] = start_label;
                node_count += 1;
            }
            end = node_count;
            labels[node_count] = end_label;
            node_count += 1;
        } else {
            let mut found_end = find_last_node(end_label, &labels, node_count);
            if start == MAX_NODE_COUNT {
                start = node_count;
                labels[node_count] = start_label;
                node_count += 1;
            }
            if found_end == MAX_NODE_COUNT {
                found_end = node_count;
                labels[node_count] = end_label;
                node_count += 1;
            }
            end = found_end;
        }
        edge_starts[edge] = start;
        edge_ends[edge] = end;
    }

    let mut marked = [false; MAX_NODE_COUNT];
    let mut roots = 0_i64;
    for root in 0..node_count {
        if marked[root] { continue; }
        let mut visited = [false; MAX_NODE_COUNT];
        visit(root, edge_count, &edge_starts, &edge_ends, &mut visited);
        for node in 0..node_count {
            if visited[node] { marked[node] = true; }
        }
        roots += 1;
    }
    roots
}
