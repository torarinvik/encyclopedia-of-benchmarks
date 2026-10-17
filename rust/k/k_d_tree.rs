const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;

#[derive(Clone, Copy)]
struct Node { point: usize, left: Option<usize>, right: Option<usize> }

fn partition_five(ids: &mut [usize], points: &[Vec<f64>], from: usize, to: usize, axis: usize) -> usize {
    let middle = (from + to) / 2;
    for i in from..=middle {
        let mut minimum = i;
        for j in i + 1..=to {
            if points[ids[j]][axis] < points[ids[minimum]][axis] { minimum = j; }
        }
        ids.swap(i, minimum);
    }
    middle
}

fn choose_median_of_medians(ids: &mut [usize], points: &[Vec<f64>],
                            from: usize, to: usize, axis: usize) -> usize {
    if to - from < 5 { return partition_five(ids, points, from, to, axis); }
    let mut medians_to = from;
    let mut start = from;
    while start <= to - 4 {
        let median = partition_five(ids, points, start, start + 4, axis);
        ids.swap(median, medians_to);
        medians_to += 1;
        start += 5;
    }
    let remainder = (to - from + 1) % 5;
    if remainder == 0 {
        medians_to -= 1;
    } else {
        let median = partition_five(ids, points, to - remainder + 1, to, axis);
        ids.swap(median, medians_to);
    }
    let medians_count = medians_to - from + 1;
    select_kth(ids, points, from, medians_to, (medians_count + 1) / 2, axis)
}

fn partition_three_way(ids: &mut [usize], points: &[Vec<f64>], from: usize, to: usize,
                       pivot_index: usize, axis: usize) -> (isize, usize) {
    let pivot = points[ids[pivot_index]][axis];
    let (mut i, mut j, mut k) = (from, from, to);
    while j <= k {
        let value = points[ids[j]][axis];
        if value < pivot {
            ids.swap(i, j); i += 1; j += 1;
        } else if pivot < value {
            ids.swap(j, k);
            if k == 0 { break; }
            k -= 1;
        } else { j += 1; }
    }
    (i as isize - 1, k + 1)
}

fn select_kth(ids: &mut [usize], points: &[Vec<f64>], mut from: usize,
              mut to: usize, mut rank: usize, axis: usize) -> usize {
    while from < to {
        let pivot = choose_median_of_medians(ids, points, from, to, axis);
        let (smaller_to, larger_from) = partition_three_way(ids, points, from, to, pivot, axis);
        let absolute_index = from + rank - 1;
        if absolute_index as isize <= smaller_to {
            to = smaller_to as usize;
        } else if absolute_index < larger_from {
            return absolute_index;
        } else {
            rank -= larger_from - from;
            from = larger_from;
        }
    }
    from
}

fn build_tree(points: &[Vec<f64>], indices: &[usize], dimension: usize,
              depth: usize, nodes: &mut Vec<Node>) -> Option<usize> {
    if indices.is_empty() { return None; }
    let axis = depth % dimension;
    let mut ordered = indices.to_vec();
    let count = ordered.len();
    let middle = select_kth(&mut ordered, points, 0, count - 1, (count + 1) / 2, axis);
    let current = nodes.len();
    nodes.push(Node { point: ordered[middle], left: None, right: None });
    let left = build_tree(points, &ordered[..middle], dimension, depth + 1, nodes);
    let right = build_tree(points, &ordered[middle + 1..], dimension, depth + 1, nodes);
    nodes[current].left = left;
    nodes[current].right = right;
    Some(current)
}

fn search_tree(points: &[Vec<f64>], nodes: &[Node], current: Option<usize>, axis: usize,
               query: &[f64], dimension: usize, best: &mut f64, best_point: &mut usize) {
    let Some(index) = current else { return; };
    let node = nodes[index];
    let point = &points[node.point];
    let squared: f64 = (0..dimension).map(|a| (query[a] - point[a]).powi(2)).sum();
    let distance = squared.sqrt();
    if distance < *best { *best = distance; *best_point = node.point; }
    let go_left = query[axis] <= point[axis];
    let (near, far) = if go_left { (node.left, node.right) } else { (node.right, node.left) };
    let next_axis = (axis + 1) % dimension;
    search_tree(points, nodes, near, next_axis, query, dimension, best, best_point);
    if *best >= (point[axis] - query[axis]).abs() {
        search_tree(points, nodes, far, next_axis, query, dimension, best, best_point);
    }
}

fn integer(value: f64) -> Option<i64> {
    if !value.is_finite() || value.fract() != 0.0 || value < -1000.0 || value > 1000.0 {
        None
    } else { Some(value as i64) }
}

#[no_mangle]
pub unsafe extern "C" fn k_d_tree(input: *const f64, length: usize,
                                  output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 51 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let dimension_value = values[0];
    if !dimension_value.is_finite() || dimension_value.fract() != 0.0 ||
       (dimension_value != 2.0 && dimension_value != 3.0) { return INVALID_RESULT; }
    let dimension = dimension_value as usize;
    let count_value = values[1];
    if !count_value.is_finite() || count_value.fract() != 0.0 || !(1.0..=15.0).contains(&count_value) {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    if length != 2 + dimension * (count + 1) { return INVALID_RESULT; }
    let query: Vec<f64> = values[2..2 + dimension].iter().map(|v| {
        if integer(*v).is_none() { f64::NAN } else { *v }
    }).collect();
    if query.iter().any(|v| !v.is_finite()) { return INVALID_RESULT; }
    let offset = 2 + dimension;
    let mut points = Vec::with_capacity(count);
    for i in 0..count {
        let point: Vec<f64> = values[offset + i * dimension..offset + (i + 1) * dimension].to_vec();
        if point.iter().any(|v| integer(*v).is_none()) { return INVALID_RESULT; }
        points.push(point);
    }
    for axis in 0..dimension {
        for i in 0..count { for j in i + 1..count {
            if points[i][axis] == points[j][axis] { return INVALID_RESULT; }
        }}
    }
    let distances: Vec<f64> = points.iter().map(|point| {
        (0..dimension).map(|axis| (query[axis] - point[axis]).powi(2)).sum()
    }).collect();
    let smallest = distances.iter().copied().fold(f64::INFINITY, f64::min);
    if distances.iter().filter(|distance| **distance == smallest).count() != 1 { return INVALID_RESULT; }
    let output_length = dimension + 1;
    if output.is_null() || output_capacity < output_length { return OUTPUT_ERROR; }
    let indices: Vec<usize> = (0..count).collect();
    let mut nodes = Vec::with_capacity(count);
    let root = build_tree(&points, &indices, dimension, 0, &mut nodes);
    let mut best = f64::INFINITY;
    let mut best_point = 0;
    search_tree(&points, &nodes, root, 0, &query, dimension, &mut best, &mut best_point);
    *output = best;
    for axis in 0..dimension { *output.add(axis + 1) = points[best_point][axis]; }
    output_length as i64
}
