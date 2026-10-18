const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_QUERIES: usize = 4;
const MAX_INPUT_LENGTH: usize = 62;
const MAX_VALID_INPUT_LENGTH: usize = 61;
const MAX_OUTPUT_LENGTH: usize = 5;
const MAX_TREE_NODES: usize = 2 * MAX_SAMPLES - 1;

#[derive(Clone, Copy)]
struct TreeNode {
    threshold: f64,
    feature: usize,
    label: usize,
    left: usize,
    right: usize,
    leaf: bool,
}

fn entropy(rows: &[usize; MAX_SAMPLES], start: usize, end: usize, labels: &[usize; MAX_SAMPLES]) -> f64 {
    let length = end - start;
    let mut sum = 0.0;
    for position in start..end {
        let label = labels[rows[position]];
        let first = (start..position).all(|previous| labels[rows[previous]] != label);
        if !first {
            continue;
        }
        let count = (start..end).filter(|&index| labels[rows[index]] == label).count();
        let probability = count as f64 / length as f64;
        sum += probability * probability.log2();
    }
    -sum
}

fn majority_label(rows: &[usize; MAX_SAMPLES], row_count: usize, labels: &[usize; MAX_SAMPLES]) -> usize {
    let mut counts = [0_usize; 3];
    for index in 0..row_count {
        counts[labels[rows[index]]] += 1;
    }
    let mut best_label = labels[rows[0]];
    let mut best_count = counts[best_label];
    for index in 0..row_count {
        let label = labels[rows[index]];
        if counts[label] > best_count {
            best_label = label;
            best_count = counts[label];
        }
    }
    best_label
}

fn build_tree(
    nodes: &mut [TreeNode; MAX_TREE_NODES],
    used: &mut usize,
    features: &[[f64; MAX_FEATURES]; MAX_SAMPLES],
    labels: &[usize; MAX_SAMPLES],
    rows: &[usize; MAX_SAMPLES],
    row_count: usize,
    feature_count: usize,
    max_depth: usize,
    min_samples_split: usize,
    depth: usize,
) -> Option<usize> {
    if *used >= MAX_TREE_NODES || row_count == 0 {
        return None;
    }
    let current = *used;
    *used += 1;
    let majority = majority_label(rows, row_count, labels);
    nodes[current] = TreeNode { threshold: 0.0, feature: 0, label: majority, left: 0, right: 0, leaf: true };

    let mut seen_labels = [false; 3];
    let mut unique_labels = 0;
    for index in 0..row_count {
        let label = labels[rows[index]];
        if !seen_labels[label] {
            seen_labels[label] = true;
            unique_labels += 1;
        }
    }
    if unique_labels == 1 || row_count < min_samples_split || depth >= max_depth || feature_count == 0 {
        return Some(current);
    }

    let parent_entropy = entropy(rows, 0, row_count, labels);
    let mut best_gain = 0.0;
    let mut best_feature = None;
    let mut best_threshold = 0.0;
    let mut sorted_rows = [0_usize; MAX_SAMPLES];
    for feature in 0..feature_count {
        sorted_rows[..row_count].copy_from_slice(&rows[..row_count]);
        for index in 1..row_count {
            let row = sorted_rows[index];
            let mut position = index;
            while position > 0 && features[sorted_rows[position - 1]][feature] > features[row][feature] {
                sorted_rows[position] = sorted_rows[position - 1];
                position -= 1;
            }
            sorted_rows[position] = row;
        }
        for split in 1..row_count {
            let left_value = features[sorted_rows[split - 1]][feature];
            let right_value = features[sorted_rows[split]][feature];
            if left_value == right_value {
                continue;
            }
            let threshold = (left_value + right_value) / 2.0;
            let left_weight = split as f64 / row_count as f64;
            let right_weight = (row_count - split) as f64 / row_count as f64;
            let gain = parent_entropy
                - left_weight * entropy(&sorted_rows, 0, split, labels)
                - right_weight * entropy(&sorted_rows, split, row_count, labels);
            if gain > best_gain {
                best_gain = gain;
                best_feature = Some(feature);
                best_threshold = threshold;
            }
        }
    }
    let Some(feature) = best_feature else {
        return Some(current);
    };

    let mut left_rows = [0_usize; MAX_SAMPLES];
    let mut right_rows = [0_usize; MAX_SAMPLES];
    let mut left_count = 0;
    let mut right_count = 0;
    for index in 0..row_count {
        let row = rows[index];
        if features[row][feature] < best_threshold {
            left_rows[left_count] = row;
            left_count += 1;
        } else {
            right_rows[right_count] = row;
            right_count += 1;
        }
    }
    if left_count == 0 || right_count == 0 {
        return Some(current);
    }
    let left = build_tree(nodes, used, features, labels, &left_rows, left_count, feature_count,
        max_depth, min_samples_split, depth + 1)?;
    let right = build_tree(nodes, used, features, labels, &right_rows, right_count, feature_count,
        max_depth, min_samples_split, depth + 1)?;
    nodes[current].leaf = false;
    nodes[current].feature = feature;
    nodes[current].threshold = best_threshold;
    nodes[current].left = left;
    nodes[current].right = right;
    Some(current)
}

fn predict(nodes: &[TreeNode; MAX_TREE_NODES], mut node: usize, query: &[f64; MAX_FEATURES]) -> usize {
    while !nodes[node].leaf {
        node = if query[nodes[node].feature] < nodes[node].threshold {
            nodes[node].left
        } else {
            nodes[node].right
        };
    }
    nodes[node].label
}

fn integer_in_range(value: f64, minimum: usize, maximum: usize) -> bool {
    value.is_finite() && value >= minimum as f64 && value <= maximum as f64 && value.fract() == 0.0
}

fn valid_feature(value: f64) -> bool {
    value.is_finite() && (-4.0..=4.0).contains(&value) && (value * 4.0).fract() == 0.0
}

#[no_mangle]
pub unsafe extern "C" fn decision_tree_rust_id3(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 10 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    if !integer_in_range(values[0], 0, 6) || !integer_in_range(values[1], 2, MAX_SAMPLES) ||
        !integer_in_range(values[2], 2, MAX_SAMPLES) || !integer_in_range(values[3], 1, MAX_FEATURES) {
        return -1;
    }
    let max_depth = values[0] as usize;
    let min_samples_split = values[1] as usize;
    let sample_count = values[2] as usize;
    let feature_count = values[3] as usize;
    let training_start = 4;
    let row_width = feature_count + 1;
    let query_count_index = training_start + sample_count * row_width;
    if input_length <= query_count_index || !integer_in_range(values[query_count_index], 1, MAX_QUERIES) {
        return -1;
    }
    let query_count = values[query_count_index] as usize;
    let query_start = query_count_index + 1;
    if input_length != query_start + query_count * feature_count || input_length > MAX_VALID_INPUT_LENGTH {
        return -1;
    }

    let mut features = [[0.0_f64; MAX_FEATURES]; MAX_SAMPLES];
    let mut labels = [0_usize; MAX_SAMPLES];
    let mut rows = [0_usize; MAX_SAMPLES];
    let mut queries = [[0.0_f64; MAX_FEATURES]; MAX_QUERIES];
    for row in 0..sample_count {
        rows[row] = row;
        let offset = training_start + row * row_width;
        for feature in 0..feature_count {
            let value = values[offset + feature];
            if !valid_feature(value) {
                return -1;
            }
            features[row][feature] = value;
        }
        let label = values[offset + feature_count];
        if !integer_in_range(label, 0, 2) {
            return -1;
        }
        labels[row] = label as usize;
    }
    for row in 0..query_count {
        for feature in 0..feature_count {
            let value = values[query_start + row * feature_count + feature];
            if !valid_feature(value) {
                return -1;
            }
            queries[row][feature] = value;
        }
    }

    let empty = TreeNode { threshold: 0.0, feature: 0, label: 0, left: 0, right: 0, leaf: true };
    let mut nodes = [empty; MAX_TREE_NODES];
    let mut used = 0;
    let Some(root) = build_tree(&mut nodes, &mut used, &features, &labels, &rows, sample_count,
        feature_count, max_depth, min_samples_split, 0) else {
        return -1;
    };
    let mut staged = [0.0_f64; MAX_OUTPUT_LENGTH];
    staged[0] = query_count as f64;
    for row in 0..query_count {
        staged[row + 1] = predict(&nodes, root, &queries[row]) as f64;
    }
    if output.is_null() || output_capacity < query_count + 1 {
        return -2;
    }
    for index in 0..query_count + 1 {
        unsafe { *output.add(index) = staged[index]; }
    }
    (query_count + 1) as i64
}
