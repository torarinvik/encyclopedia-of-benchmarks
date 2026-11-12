use std::slice;

const MAX_N: usize = 12;
const MAX_INPUT_VALUES: usize = 3 * MAX_N + 1;
const MAX_OUTPUT_WORDS: usize = MAX_N + 1;
const MAX_WEIGHT: i64 = 1_000_000;

fn find_root(parent: &mut [usize; MAX_N], mut vertex: usize) -> usize {
    let mut root = vertex;
    while parent[root] != root { root = parent[root]; }
    while parent[vertex] != vertex {
        let next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    root
}

fn compare_ratio(left_c: i64, left_d: i64, right_c: i64, right_d: i64) -> i32 {
    let left_zero = left_c == 0 && left_d == 0;
    let right_zero = right_c == 0 && right_d == 0;
    if left_zero != right_zero { return if left_zero { -1 } else { 1 }; }
    let lhs = left_c * right_d;
    let rhs = left_d * right_c;
    (lhs > rhs) as i32 - (lhs < rhs) as i32
}

#[no_mangle]
pub unsafe extern "C" fn rooted_tree_topological_order_with_minimum_inversions(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 3 || length > MAX_INPUT_VALUES { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let n_value = input[0];
    if n_value < 1 || n_value > MAX_N as i64 || length != 3 * n_value as usize { return -1; }
    let n = n_value as usize;

    let mut tree_parent = [0usize; MAX_N];
    for vertex in 1..n {
        let p = input[vertex];
        if p < 0 || p >= vertex as i64 { return -1; }
        tree_parent[vertex] = p as usize;
    }

    let mut original_c = [0i64; MAX_N];
    let mut original_d = [0i64; MAX_N];
    let mut aggregate_c = [0i64; MAX_N];
    let mut aggregate_d = [0i64; MAX_N];
    let (mut sum_c, mut sum_d) = (0i64, 0i64);
    for vertex in 0..n {
        let (c, d) = (input[n + vertex], input[2 * n + vertex]);
        if c < 0 || c > MAX_WEIGHT || d < 0 || d > MAX_WEIGHT { return -1; }
        sum_c += c;
        sum_d += d;
        if sum_c > MAX_WEIGHT || sum_d > MAX_WEIGHT { return -1; }
        original_c[vertex] = c;
        original_d[vertex] = d;
        aggregate_c[vertex] = c;
        aggregate_d[vertex] = d;
    }

    let mut dsu_parent = [0usize; MAX_N];
    let mut component_label = [0usize; MAX_N];
    let mut active = [false; MAX_N];
    let mut link = [0usize; MAX_N];
    for vertex in 0..n {
        dsu_parent[vertex] = vertex;
        component_label[vertex] = vertex;
        active[vertex] = vertex != 0;
        link[vertex] = vertex;
    }

    for _ in 0..n - 1 {
        let mut selected: Option<usize> = None;
        for candidate in 1..n {
            if !active[candidate] { continue; }
            let Some(current) = selected else { selected = Some(candidate); continue; };
            let comparison = compare_ratio(aggregate_c[candidate], aggregate_d[candidate],
                                           aggregate_c[current], aggregate_d[current]);
            if comparison > 0 || (comparison == 0 && candidate > current) {
                selected = Some(candidate);
            }
        }
        let Some(child) = selected else { return -1; };
        let parent_component = find_root(&mut dsu_parent, tree_parent[child]);
        let target = component_label[parent_component];
        let child_component = find_root(&mut dsu_parent, child);
        if child_component == parent_component { return -1; }
        aggregate_c[target] += aggregate_c[child];
        aggregate_d[target] += aggregate_d[child];
        dsu_parent[child_component] = parent_component;
        component_label[parent_component] = target;
        active[child] = false;
        if target != 0 { active[target] = true; }
        let next = link[child];
        link[child] = link[target];
        link[target] = next;
    }

    let mut traversal = [0usize; MAX_N];
    let mut count = 0usize;
    let mut vertex = link[0];
    while count < n {
        traversal[count] = vertex;
        count += 1;
        if vertex == 0 { break; }
        vertex = link[vertex];
    }
    if count != n || traversal[count - 1] != 0 { return -1; }

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    let (mut prefix_d, mut objective) = (0i64, 0i64);
    for index in 0..n {
        let ordered_vertex = traversal[n - 1 - index];
        words[index + 1] = ordered_vertex as i64;
        objective += prefix_d * original_c[ordered_vertex];
        prefix_d += original_d[ordered_vertex];
    }
    words[0] = objective;
    let output_bytes = 8 * (n + 1);
    if output_ptr.is_null() || capacity < output_bytes { return -2; }
    let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
    for word in 0..n + 1 {
        output[word * 8..word * 8 + 8].copy_from_slice(&words[word].to_le_bytes());
    }
    output_bytes as i64
}
