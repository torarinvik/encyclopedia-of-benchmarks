const MAX_NODE_COUNT: usize = 256;
const MAX_EDGE_COUNT: usize = 2047;

fn find_root(parent: &mut [usize; MAX_NODE_COUNT + 1], mut node: usize) -> usize {
    while parent[node] != node {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    node
}

#[no_mangle]
pub unsafe extern "C" fn connected_components_with_dsu(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let node_arg = *input;
    let edge_arg = *input.add(1);
    if !(0..=MAX_NODE_COUNT as i64).contains(&node_arg) ||
        !(0..=MAX_EDGE_COUNT as i64).contains(&edge_arg) { return -1; }
    let node_count = node_arg as usize;
    let edge_count = edge_arg as usize;
    if length != 2 + 2 * edge_count { return -1; }

    let mut parent = [0usize; MAX_NODE_COUNT + 1];
    let mut set_size = [0usize; MAX_NODE_COUNT + 1];
    for node in 1..=node_count { parent[node] = node; set_size[node] = 1; }
    let mut component_count = node_count;
    for edge in 0..edge_count {
        let left_arg = *input.add(2 + 2 * edge);
        let right_arg = *input.add(3 + 2 * edge);
        if left_arg < 1 || left_arg > node_count as i64 ||
            right_arg < 1 || right_arg > node_count as i64 { return -1; }
        let mut left = find_root(&mut parent, left_arg as usize);
        let mut right = find_root(&mut parent, right_arg as usize);
        if left == right { continue; }
        if set_size[left] < set_size[right] { std::mem::swap(&mut left, &mut right); }
        parent[right] = left;
        set_size[left] += set_size[right];
        component_count -= 1;
    }
    component_count as i64
}
