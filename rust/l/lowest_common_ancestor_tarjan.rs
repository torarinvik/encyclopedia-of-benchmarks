const MAX_NODE_COUNT: usize = 256;
const MAX_QUERY_COUNT: usize = 1024;
const MAX_ADJACENCY_COUNT: usize = 2 * (MAX_NODE_COUNT - 1);
const MAX_QUERY_ADJACENCY_COUNT: usize = 2 * MAX_QUERY_COUNT;

fn find_root(parent: &mut [usize; MAX_NODE_COUNT], node: usize) -> usize {
    let mut root = node;
    while parent[root] != root { root = parent[root]; }
    let mut current = node;
    while parent[current] != current {
        let next = parent[current];
        parent[current] = root;
        current = next;
    }
    root
}

fn unite(parent: &mut [usize; MAX_NODE_COUNT], rank: &mut [u8; MAX_NODE_COUNT],
         left: usize, right: usize) {
    let left_root = find_root(parent, left);
    let right_root = find_root(parent, right);
    if left_root == right_root { return; }
    if rank[left_root] < rank[right_root] { parent[left_root] = right_root; }
    else if rank[left_root] > rank[right_root] { parent[right_root] = left_root; }
    else { parent[right_root] = left_root; rank[left_root] += 1; }
}

#[no_mangle]
pub unsafe extern "C" fn lowest_common_ancestor_tarjan(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let node_arg = *input;
    if !(1..=MAX_NODE_COUNT as i64).contains(&node_arg) { return -1; }
    let node_count = node_arg as usize;
    let root_arg = *input.add(1);
    let edge_arg = *input.add(2);
    let query_arg = *input.add(3);
    if root_arg < 0 || root_arg >= node_count as i64 || edge_arg != (node_count - 1) as i64 ||
        !(0..=MAX_QUERY_COUNT as i64).contains(&query_arg) { return -1; }
    let root = root_arg as usize;
    let edge_count = edge_arg as usize;
    let query_count = query_arg as usize;
    if length != 4 + 2 * edge_count + 2 * query_count { return -1; }

    let mut validation_parent = [0usize; MAX_NODE_COUNT];
    let mut dsu_parent = [0usize; MAX_NODE_COUNT];
    let mut ancestor = [0usize; MAX_NODE_COUNT];
    let mut validation_rank = [0u8; MAX_NODE_COUNT];
    let mut dsu_rank = [0u8; MAX_NODE_COUNT];
    let mut edge_head = [-1i64; MAX_NODE_COUNT];
    let mut edge_to = [0i64; MAX_ADJACENCY_COUNT];
    let mut edge_next = [0i64; MAX_ADJACENCY_COUNT];
    let mut query_head = [-1i64; MAX_NODE_COUNT];
    let mut query_to = [0i64; MAX_QUERY_ADJACENCY_COUNT];
    let mut query_next = [0i64; MAX_QUERY_ADJACENCY_COUNT];
    let mut query_id = [0i64; MAX_QUERY_ADJACENCY_COUNT];
    let mut answers = [0i64; MAX_QUERY_COUNT];
    let mut tree_parent = [-1i64; MAX_NODE_COUNT];
    let mut cursor = [-1i64; MAX_NODE_COUNT];
    let mut visited = [false; MAX_NODE_COUNT];
    let mut finished = [false; MAX_NODE_COUNT];
    let mut stack = [0usize; MAX_NODE_COUNT];
    for node in 0..node_count {
        validation_parent[node] = node;
        dsu_parent[node] = node;
        ancestor[node] = node;
    }

    for edge in 0..edge_count {
        let left_arg = *input.add(4 + 2 * edge);
        let right_arg = *input.add(5 + 2 * edge);
        if left_arg < 0 || right_arg < 0 || left_arg >= node_count as i64 ||
            right_arg >= node_count as i64 || left_arg == right_arg { return -1; }
        let left = left_arg as usize;
        let right = right_arg as usize;
        if find_root(&mut validation_parent, left) == find_root(&mut validation_parent, right) { return -1; }
        unite(&mut validation_parent, &mut validation_rank, left, right);
        let forward = 2 * edge;
        let reverse = forward + 1;
        edge_to[forward] = right as i64;
        edge_next[forward] = edge_head[left];
        edge_head[left] = forward as i64;
        edge_to[reverse] = left as i64;
        edge_next[reverse] = edge_head[right];
        edge_head[right] = reverse as i64;
    }
    let root_component = find_root(&mut validation_parent, root);
    for node in 0..node_count {
        if find_root(&mut validation_parent, node) != root_component { return -1; }
    }
    for query in 0..query_count {
        let left_arg = *input.add(4 + 2 * edge_count + 2 * query);
        let right_arg = *input.add(5 + 2 * edge_count + 2 * query);
        if left_arg < 0 || right_arg < 0 || left_arg >= node_count as i64 ||
            right_arg >= node_count as i64 { return -1; }
        let left = left_arg as usize;
        let right = right_arg as usize;
        let first = 2 * query;
        let second = first + 1;
        query_to[first] = right as i64;
        query_id[first] = query as i64;
        query_next[first] = query_head[left];
        query_head[left] = first as i64;
        query_to[second] = left as i64;
        query_id[second] = query as i64;
        query_next[second] = query_head[right];
        query_head[right] = second as i64;
    }
    if query_count > output_capacity || (query_count != 0 && output.is_null()) { return -2; }

    let mut top = 0usize;
    stack[top] = root;
    top += 1;
    visited[root] = true;
    cursor[root] = edge_head[root];
    while top > 0 {
        let node = stack[top - 1];
        let edge = cursor[node];
        if edge >= 0 {
            cursor[node] = edge_next[edge as usize];
            let child = edge_to[edge as usize] as usize;
            if child as i64 == tree_parent[node] { continue; }
            if visited[child] { return -1; }
            visited[child] = true;
            tree_parent[child] = node as i64;
            cursor[child] = edge_head[child];
            stack[top] = child;
            top += 1;
            continue;
        }
        finished[node] = true;
        let mut item = query_head[node];
        while item >= 0 {
            let index = item as usize;
            let other = query_to[index] as usize;
            if finished[other] {
                answers[query_id[index] as usize] = ancestor[find_root(&mut dsu_parent, other)] as i64;
            }
            item = query_next[index];
        }
        top -= 1;
        if tree_parent[node] >= 0 {
            let parent = tree_parent[node] as usize;
            unite(&mut dsu_parent, &mut dsu_rank, parent, node);
            let component = find_root(&mut dsu_parent, parent);
            ancestor[component] = parent;
        }
    }
    for query in 0..query_count { *output.add(query) = answers[query] as u8; }
    query_count as i64
}
