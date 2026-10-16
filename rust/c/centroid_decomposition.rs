use std::slice;

const MAX_NODES: usize = 64;
const MAX_DIRECTED_EDGES: usize = 2 * (MAX_NODES - 1);
const INVALID_PARENT: i32 = -2;

fn find_set(parent: &[i32; MAX_NODES], mut node: i32) -> i32 {
    while parent[node as usize] != node {
        node = parent[node as usize];
    }
    node
}

#[no_mangle]
pub unsafe extern "C" fn centroid_decomposition(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=2 * MAX_NODES - 1).contains(&length) {
        return -1;
    }
    let values = slice::from_raw_parts(input, length);
    if !(1..=MAX_NODES as i64).contains(&values[0]) {
        return -1;
    }
    let node_count = values[0] as usize;
    if length != 2 * node_count - 1 {
        return -1;
    }

    let mut set_parent = [0i32; MAX_NODES];
    let mut head = [-1i32; MAX_NODES];
    let mut edge_to = [0i32; MAX_DIRECTED_EDGES];
    let mut edge_next = [-1i32; MAX_DIRECTED_EDGES];
    for node in 0..node_count {
        set_parent[node] = node as i32;
    }
    let mut edge_count = 0usize;
    let mut position = 1usize;
    while position < length {
        let left_value = values[position];
        let right_value = values[position + 1];
        if left_value < 0 || left_value >= node_count as i64
            || right_value < 0 || right_value >= node_count as i64
            || left_value == right_value
        {
            return -1;
        }
        let left = left_value as i32;
        let right = right_value as i32;
        let left_root = find_set(&set_parent, left);
        let right_root = find_set(&set_parent, right);
        if left_root == right_root {
            return -1;
        }
        set_parent[right_root as usize] = left_root;
        edge_to[edge_count] = right;
        edge_next[edge_count] = head[left as usize];
        head[left as usize] = edge_count as i32;
        edge_count += 1;
        edge_to[edge_count] = left;
        edge_next[edge_count] = head[right as usize];
        head[right as usize] = edge_count as i32;
        edge_count += 1;
        position += 2;
    }
    if output_capacity < node_count * 4 || output.is_null() {
        return -2;
    }

    let mut removed = [false; MAX_NODES];
    let mut traversal_parent = [INVALID_PARENT; MAX_NODES];
    let mut subtree_size = [0i32; MAX_NODES];
    let mut order = [0i32; MAX_NODES];
    let mut stack = [0i32; MAX_NODES];
    let mut task_node = [0i32; MAX_NODES];
    let mut task_parent = [0i32; MAX_NODES];
    let mut decomposition_parent = [INVALID_PARENT; MAX_NODES];
    let mut task_count = 1usize;
    task_node[0] = 0;
    task_parent[0] = -1;

    while task_count > 0 {
        task_count -= 1;
        let start = task_node[task_count];
        let centroid_parent = task_parent[task_count];
        for node in 0..node_count {
            traversal_parent[node] = INVALID_PARENT;
        }
        let mut stack_count = 1usize;
        let mut order_count = 0usize;
        stack[0] = start;
        traversal_parent[start as usize] = -1;
        while stack_count > 0 {
            stack_count -= 1;
            let node = stack[stack_count];
            order[order_count] = node;
            order_count += 1;
            subtree_size[node as usize] = 1;
            let mut edge = head[node as usize];
            while edge >= 0 {
                let edge_index = edge as usize;
                let neighbor = edge_to[edge_index];
                if neighbor != traversal_parent[node as usize]
                    && !removed[neighbor as usize]
                    && traversal_parent[neighbor as usize] == INVALID_PARENT
                {
                    traversal_parent[neighbor as usize] = node;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
                edge = edge_next[edge_index];
            }
        }
        let mut index = order_count;
        while index > 0 {
            index -= 1;
            let node = order[index];
            let parent = traversal_parent[node as usize];
            if parent >= 0 {
                subtree_size[parent as usize] += subtree_size[node as usize];
            }
        }

        let mut centroid = -1i32;
        let mut smallest_largest_branch = node_count as i32 + 1;
        for index in 0..order_count {
            let node = order[index];
            let node_index = node as usize;
            let mut largest_branch = order_count as i32 - subtree_size[node_index];
            let mut edge = head[node_index];
            while edge >= 0 {
                let edge_index = edge as usize;
                let neighbor = edge_to[edge_index];
                if traversal_parent[neighbor as usize] == node {
                    largest_branch = largest_branch.max(subtree_size[neighbor as usize]);
                }
                edge = edge_next[edge_index];
            }
            if largest_branch < smallest_largest_branch
                || (largest_branch == smallest_largest_branch && node < centroid)
            {
                centroid = node;
                smallest_largest_branch = largest_branch;
            }
        }
        decomposition_parent[centroid as usize] = centroid_parent;
        removed[centroid as usize] = true;
        let mut edge = head[centroid as usize];
        while edge >= 0 {
            let edge_index = edge as usize;
            let neighbor = edge_to[edge_index];
            if !removed[neighbor as usize] {
                task_node[task_count] = neighbor;
                task_parent[task_count] = centroid;
                task_count += 1;
            }
            edge = edge_next[edge_index];
        }
    }

    let output = slice::from_raw_parts_mut(output, node_count * 4);
    for node in 0..node_count {
        let bytes = decomposition_parent[node].to_le_bytes();
        output[4 * node..4 * node + 4].copy_from_slice(&bytes);
    }
    node_count as i64
}
