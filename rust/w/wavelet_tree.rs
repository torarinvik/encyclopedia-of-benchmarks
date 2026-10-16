const MAX_ITEMS: usize = 64;
const MAX_QUERIES: usize = 128;
const MAX_NODES: usize = 2 * MAX_ITEMS - 1;
const MAX_PACKED_LENGTH: usize = MAX_ITEMS + 2 + 5 * MAX_QUERIES;
const CHECKSUM_OFFSET: i64 = 1_000_001;

#[derive(Default)]
struct WaveletNode {
    low: i64,
    high: i64,
    left: Option<usize>,
    right: Option<usize>,
    prefix_left: Vec<usize>,
}

// Build a stable value partition. prefix_left[k] counts left values in [0,k).
fn build_tree(values: &[i64], low: i64, high: i64, nodes: &mut Vec<WaveletNode>) -> usize {
    let node_id = nodes.len();
    nodes.push(WaveletNode {
        low,
        high,
        left: None,
        right: None,
        prefix_left: vec![0; values.len() + 1],
    });

    if low == high || values.is_empty() {
        return node_id;
    }

    let middle = low + (high - low) / 2;
    let mut left_values = Vec::with_capacity(values.len());
    let mut right_values = Vec::with_capacity(values.len());
    for (i, &value) in values.iter().enumerate() {
        if value <= middle {
            left_values.push(value);
        } else {
            right_values.push(value);
        }
        nodes[node_id].prefix_left[i + 1] = left_values.len();
    }

    if !left_values.is_empty() {
        let child = build_tree(&left_values, low, middle, nodes);
        nodes[node_id].left = Some(child);
    }
    if !right_values.is_empty() {
        let child = build_tree(&right_values, middle + 1, high, nodes);
        nodes[node_id].right = Some(child);
    }
    node_id
}

// Count value occurrences in the first `count` positions of this node.
fn rank_prefix(nodes: &[WaveletNode], node_id: Option<usize>, value: i64, count: usize) -> i64 {
    let Some(node_id) = node_id else {
        return 0;
    };
    if count == 0 {
        return 0;
    }
    let node = &nodes[node_id];
    if node.low == node.high {
        return if node.low == value { count as i64 } else { 0 };
    }

    let left_count = node.prefix_left[count];
    let middle = node.low + (node.high - node.low) / 2;
    if value <= middle {
        rank_prefix(nodes, node.left, value, left_count)
    } else {
        rank_prefix(nodes, node.right, value, count - left_count)
    }
}

// Return the zero-based kth value in the remapped half-open interval [left,right).
fn quantile(nodes: &[WaveletNode], node_id: usize, left: usize, right: usize, k: usize) -> i64 {
    let node = &nodes[node_id];
    if node.low == node.high {
        return node.low;
    }

    let left_before = node.prefix_left[left];
    let left_after = node.prefix_left[right];
    let in_left = left_after - left_before;
    if k < in_left {
        quantile(nodes, node.left.unwrap(), left_before, left_after, k)
    } else {
        quantile(
            nodes,
            node.right.unwrap(),
            left - left_before,
            right - left_after,
            k - in_left,
        )
    }
}

// Count values in [value_low,value_high] for the remapped [left,right) interval.
fn range_count(
    nodes: &[WaveletNode],
    node_id: Option<usize>,
    left: usize,
    right: usize,
    value_low: i64,
    value_high: i64,
) -> i64 {
    let Some(node_id) = node_id else {
        return 0;
    };
    if left >= right {
        return 0;
    }
    let node = &nodes[node_id];
    if value_high < node.low || value_low > node.high {
        return 0;
    }
    if value_low <= node.low && node.high <= value_high {
        return (right - left) as i64;
    }
    if node.low == node.high {
        return 0;
    }

    let left_before = node.prefix_left[left];
    let left_after = node.prefix_left[right];
    range_count(
        nodes,
        node.left,
        left_before,
        left_after,
        value_low,
        value_high,
    ) + range_count(
        nodes,
        node.right,
        left - left_before,
        right - left_after,
        value_low,
        value_high,
    )
}

#[no_mangle]
pub unsafe extern "C" fn wavelet_tree_benchmark(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_PACKED_LENGTH {
        return -1;
    }

    let values = std::slice::from_raw_parts(values, length);
    if !(1..=MAX_ITEMS as i64).contains(&values[0]) {
        return -1;
    }
    let item_count = values[0] as usize;
    if length < item_count + 2 {
        return -1;
    }

    let data = &values[1..item_count + 1];
    if data.iter().any(|&value| !(-1000..=1000).contains(&value)) {
        return -1;
    }
    let query_count_value = values[item_count + 1];
    if !(0..=MAX_QUERIES as i64).contains(&query_count_value)
        || length != item_count + 2 + 5 * query_count_value as usize
    {
        return -1;
    }

    let value_low = *data.iter().min().unwrap();
    let value_high = *data.iter().max().unwrap();
    let mut nodes = Vec::with_capacity(MAX_NODES);
    let root = build_tree(data, value_low, value_high, &mut nodes);
    let query_count = query_count_value as usize;
    let mut checksum = 0_i64;

    for query_index in 0..query_count {
        let offset = item_count + 2 + 5 * query_index;
        let opcode = values[offset];
        let a = values[offset + 1];
        let b = values[offset + 2];
        let c = values[offset + 3];
        let d = values[offset + 4];
        let answer;

        if opcode == 0 {
            if !(-1000..=1000).contains(&a) || b < -1 || b >= item_count as i64 {
                return -1;
            }
            answer = rank_prefix(&nodes, Some(root), a, (b + 1) as usize);
        } else if opcode == 1 {
            if a < 0 || b < a || b >= item_count as i64 || c < 0 || c > b - a {
                return -1;
            }
            answer = quantile(&nodes, root, a as usize, b as usize + 1, c as usize);
        } else if opcode == 2 {
            if a < 0 || b < a || b >= item_count as i64 || c > d || c < -1000 || d > 1000 {
                return -1;
            }
            answer = range_count(&nodes, Some(root), a as usize, b as usize + 1, c, d);
        } else {
            return -1;
        }

        checksum += (query_index as i64 + 1) * (answer + CHECKSUM_OFFSET);
    }
    checksum
}
