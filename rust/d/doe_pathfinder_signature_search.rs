const MAX_NODES: i64 = 10;
const MAX_EDGES: i64 = 100;
const MAX_SIGNATURE_LENGTH: i64 = 4;
const MAX_LABEL: i64 = 7;

fn search_leg(input: &[i64], edge_count: usize, labels_start: usize, signature_start: usize,
              signature_length: usize, node: usize, signature_index: usize,
              visited: &mut u16) -> bool {
    let bit = 1u16 << node;
    if (*visited & bit) != 0 { return false; }
    *visited |= bit;

    let target_label = input[signature_start + signature_index];
    for edge in 0..edge_count {
        if input[3 + 2 * edge] as usize != node { continue; }
        let target = input[4 + 2 * edge] as usize;
        if input[labels_start + target] != target_label { continue; }
        if signature_index + 1 == signature_length { return true; }
        let mut next_visited = 0u16;
        if search_leg(input, edge_count, labels_start, signature_start, signature_length,
                      target, signature_index + 1, &mut next_visited) { return true; }
    }

    for edge in 0..edge_count {
        if input[3 + 2 * edge] as usize != node { continue; }
        let target = input[4 + 2 * edge] as usize;
        if search_leg(input, edge_count, labels_start, signature_start, signature_length,
                      target, signature_index, visited) { return true; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn doe_pathfinder_signature_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -2; }
    let input = std::slice::from_raw_parts(values, length);
    if !(1..=MAX_NODES).contains(&input[0]) || !(0..=MAX_EDGES).contains(&input[1]) ||
        !(2..=MAX_SIGNATURE_LENGTH).contains(&input[2]) { return -2; }
    let node_count = input[0] as usize;
    let edge_count = input[1] as usize;
    let signature_length = input[2] as usize;
    if edge_count > node_count * node_count ||
        length != 3 + 2 * edge_count + node_count + signature_length { return -2; }

    for edge in 0..edge_count {
        let from = input[3 + 2 * edge];
        let to = input[4 + 2 * edge];
        if from < 0 || from >= node_count as i64 || to < 0 || to >= node_count as i64 { return -2; }
        for previous in 0..edge {
            if input[3 + 2 * previous] == from && input[4 + 2 * previous] == to { return -2; }
        }
    }
    let labels_start = 3 + 2 * edge_count;
    let signature_start = labels_start + node_count;
    if input[labels_start..labels_start + node_count].iter().any(|label| *label < -1 || *label > MAX_LABEL) ||
        input[signature_start..].iter().any(|label| *label < 0 || *label > MAX_LABEL) { return -2; }

    let first_label = input[signature_start];
    for node in 0..node_count {
        if input[labels_start + node] != first_label { continue; }
        let mut visited = 0u16;
        if search_leg(input, edge_count, labels_start, signature_start, signature_length,
                      node, 1, &mut visited) { return 1; }
    }
    0
}
