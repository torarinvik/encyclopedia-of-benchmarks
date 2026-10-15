/// Trim a strict BST and serialize the retained tree in preorder node-table order.
const MAX_NODE_COUNT: usize = 100;
const MAX_VALUE: i64 = 10000;

fn valid_bst(nodes: &[i64], node_count: usize, root_index: usize) -> bool {
    let mut parents = [0usize; MAX_NODE_COUNT];
    for index in 0..node_count {
        let value = nodes[3 * index];
        let left = nodes[3 * index + 1];
        let right = nodes[3 * index + 2];
        if value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= node_count as u64) ||
            (right >= 0 && right as u64 >= node_count as u64) { return false; }
        if left >= 0 {
            parents[left as usize] += 1;
            if parents[left as usize] > 1 { return false; }
        }
        if right >= 0 {
            parents[right as usize] += 1;
            if parents[right as usize] > 1 { return false; }
        }
    }
    if parents[root_index] != 0 { return false; }
    for index in 0..node_count {
        if index != root_index && parents[index] != 1 { return false; }
    }

    let mut stack_node = [0usize; MAX_NODE_COUNT];
    let mut stack_low = [0i64; MAX_NODE_COUNT];
    let mut stack_high = [0i64; MAX_NODE_COUNT];
    let mut seen = [false; MAX_NODE_COUNT];
    let mut top = 1usize;
    let mut visited = 0usize;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    while top > 0 {
        top -= 1;
        let index = stack_node[top];
        let lower = stack_low[top];
        let upper = stack_high[top];
        if seen[index] { return false; }
        seen[index] = true;
        visited += 1;
        let value = nodes[3 * index];
        if value <= lower || value >= upper { return false; }
        let left = nodes[3 * index + 1];
        let right = nodes[3 * index + 2];
        if right >= 0 {
            stack_node[top] = right as usize;
            stack_low[top] = value;
            stack_high[top] = upper;
            top += 1;
        }
        if left >= 0 {
            stack_node[top] = left as usize;
            stack_low[top] = lower;
            stack_high[top] = value;
            top += 1;
        }
    }
    visited == node_count
}

fn trim_node(nodes: &[i64], node: i64, low: i64, high: i64,
             output: &mut [i64], output_count: &mut usize) -> i64 {
    if node == -1 { return -1; }
    let index = node as usize;
    let value = nodes[3 * index];
    let left = nodes[3 * index + 1];
    let right = nodes[3 * index + 2];
    if value < low { return trim_node(nodes, right, low, high, output, output_count); }
    if value > high { return trim_node(nodes, left, low, high, output, output_count); }
    let trimmed_index = *output_count;
    *output_count += 1;
    let offset = 1 + 3 * trimmed_index;
    output[offset] = value;
    output[offset + 1] = -1;
    output[offset + 2] = -1;
    output[offset + 1] = trim_node(nodes, left, low, high, output, output_count);
    output[offset + 2] = trim_node(nodes, right, low, high, output, output_count);
    trimmed_index as i64
}

#[no_mangle]
pub unsafe extern "C" fn trim_bst(nodes: *const i64, node_count: usize, root_index: i64,
                                   low: i64, high: i64, output: *mut i64,
                                   output_capacity: usize) -> i64 {
    if node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high { return -1; }
    if node_count == 0 {
        if root_index != -1 { return -1; }
        if output.is_null() || output_capacity < 1 { return -2; }
        *output = -1;
        return 1;
    }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let node_values = std::slice::from_raw_parts(nodes, 3 * node_count);
    if !valid_bst(node_values, node_count, root_index as usize) { return -1; }
    let required = 1 + 3 * node_count;
    if output.is_null() || output_capacity < required { return -2; }
    let output_values = std::slice::from_raw_parts_mut(output, output_capacity);
    let mut output_count = 0usize;
    output_values[0] = trim_node(node_values, root_index, low, high, output_values, &mut output_count);
    (1 + 3 * output_count) as i64
}
