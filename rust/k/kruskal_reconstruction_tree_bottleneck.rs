const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_NODES: usize = MAX_VERTICES + MAX_EDGES;
const LOG_LEVELS: usize = 5;
const MAX_INPUT_LENGTH: usize = 67;

#[derive(Clone, Copy, Default)]
struct Edge {
    from: usize,
    to: usize,
    weight: i64,
    original_index: usize,
}

fn find_root(parent: &mut [usize; MAX_VERTICES], start: usize) -> usize {
    let mut root = start;
    while parent[root] != root { root = parent[root]; }
    let mut vertex = start;
    while parent[vertex] != vertex {
        let next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    root
}

fn edge_greater(left: Edge, right: Edge) -> bool {
    left.weight > right.weight || (left.weight == right.weight && left.original_index > right.original_index)
}

#[no_mangle]
pub unsafe extern "C" fn kruskal_reconstruction_tree_bottleneck(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    let q_value = values[2];
    if !(1..=8).contains(&n_value) || !(0..=16).contains(&m_value) || !(1..=8).contains(&q_value) {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    let q = q_value as usize;
    let query_offset = 3 + 3 * m;
    if length != query_offset + 2 * q { return -1; }

    let mut edges = [Edge::default(); MAX_EDGES];
    for edge_index in 0..m {
        let from_value = values[3 + 3 * edge_index];
        let to_value = values[4 + 3 * edge_index];
        let weight = values[5 + 3 * edge_index];
        if from_value < 0 || from_value >= n as i64 || to_value < 0 || to_value >= n as i64
            || !(0..=1_000_000).contains(&weight) {
            return -1;
        }
        edges[edge_index] = Edge {
            from: from_value as usize,
            to: to_value as usize,
            weight,
            original_index: edge_index,
        };
    }
    for query in 0..q {
        for side in 0..2 {
            let vertex = values[query_offset + 2 * query + side];
            if vertex < 0 || vertex >= n as i64 { return -1; }
        }
    }

    for index in 1..m {
        let edge = edges[index];
        let mut position = index;
        while position > 0 && edge_greater(edges[position - 1], edge) {
            edges[position] = edges[position - 1];
            position -= 1;
        }
        edges[position] = edge;
    }

    let mut dsu_parent = [0usize; MAX_VERTICES];
    let mut dsu_size = [0usize; MAX_VERTICES];
    let mut tree_root = [0usize; MAX_VERTICES];
    for vertex in 0..n {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
        tree_root[vertex] = vertex;
    }
    let mut tree_parent = [-1i32; MAX_NODES];
    let mut children = [[-1i32; 2]; MAX_NODES];
    let mut label = [0i64; MAX_NODES];
    let mut node_count = n;
    for edge in edges[..m].iter().copied() {
        let mut left_root = find_root(&mut dsu_parent, edge.from);
        let mut right_root = find_root(&mut dsu_parent, edge.to);
        if left_root == right_root { continue; }
        let merged_node = node_count;
        node_count += 1;
        children[merged_node] = [tree_root[left_root] as i32, tree_root[right_root] as i32];
        label[merged_node] = edge.weight;
        tree_parent[tree_root[left_root]] = merged_node as i32;
        tree_parent[tree_root[right_root]] = merged_node as i32;
        if dsu_size[left_root] < dsu_size[right_root] { core::mem::swap(&mut left_root, &mut right_root); }
        dsu_parent[right_root] = left_root;
        dsu_size[left_root] += dsu_size[right_root];
        tree_root[left_root] = merged_node;
    }

    let mut depth = [0usize; MAX_NODES];
    let mut ancestors = [[0usize; MAX_NODES]; LOG_LEVELS];
    for root in 0..node_count {
        if tree_parent[root] >= 0 { continue; }
        ancestors[0][root] = root;
        let mut stack = [0usize; MAX_NODES];
        let mut top = 1usize;
        stack[0] = root;
        while top > 0 {
            top -= 1;
            let node = stack[top];
            for side in 0..2 {
                let child = children[node][side];
                if child < 0 { continue; }
                let child = child as usize;
                depth[child] = depth[node] + 1;
                ancestors[0][child] = node;
                stack[top] = child;
                top += 1;
            }
        }
    }
    for level in 1..LOG_LEVELS {
        for node in 0..node_count {
            ancestors[level][node] = ancestors[level - 1][ancestors[level - 1][node]];
        }
    }

    let mut checksum = 0i64;
    for query in 0..q {
        let source = values[query_offset + 2 * query] as usize;
        let destination = values[query_offset + 2 * query + 1] as usize;
        let answer = if source == destination {
            0
        } else if find_root(&mut dsu_parent, source) != find_root(&mut dsu_parent, destination) {
            -1
        } else {
            let mut left = source;
            let mut right = destination;
            if depth[left] < depth[right] { core::mem::swap(&mut left, &mut right); }
            let difference = depth[left] - depth[right];
            for level in 0..LOG_LEVELS {
                if difference & (1usize << level) != 0 { left = ancestors[level][left]; }
            }
            if left != right {
                for level in (0..LOG_LEVELS).rev() {
                    if ancestors[level][left] != ancestors[level][right] {
                        left = ancestors[level][left];
                        right = ancestors[level][right];
                    }
                }
                left = ancestors[0][left];
            }
            label[left]
        };
        checksum += (query as i64 + 1) * (answer + 2);
    }
    checksum
}
