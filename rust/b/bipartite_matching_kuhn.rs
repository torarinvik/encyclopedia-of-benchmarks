/// Kuhn DFS augmenting-path maximum matching for a bounded bipartite graph.
const MAX_SIDE: usize = 64;
const MAX_EDGES: usize = MAX_SIDE * MAX_SIDE;

fn try_augment(left: usize, right_count: usize, adjacency: &[bool], seen_right: &mut [bool; MAX_SIDE],
               pair_right: &mut [i32; MAX_SIDE]) -> bool {
    for right in 0..right_count {
        if !adjacency[left * MAX_SIDE + right] || seen_right[right] { continue; }
        seen_right[right] = true;
        let mate = pair_right[right];
        if mate < 0 || try_augment(mate as usize, right_count, adjacency, seen_right, pair_right) {
            pair_right[right] = left as i32;
            return true;
        }
    }
    false
}

#[no_mangle]
pub extern "C" fn bipartite_matching_kuhn(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let left_value = unsafe { *input };
    let right_value = unsafe { *input.add(1) };
    let edge_value = unsafe { *input.add(2) };
    if !(0..=MAX_SIDE as i64).contains(&left_value) || !(0..=MAX_SIDE as i64).contains(&right_value) ||
        !(0..=MAX_EDGES as i64).contains(&edge_value) { return -1; }
    let left_count = left_value as usize;
    let right_count = right_value as usize;
    let edge_count = edge_value as usize;
    if length != 3 + 2 * edge_count { return -1; }
    let mut adjacency = [false; MAX_SIDE * MAX_SIDE];
    for edge in 0..edge_count {
        let left = unsafe { *input.add(3 + 2 * edge) };
        let right = unsafe { *input.add(4 + 2 * edge) };
        if left < 0 || left >= left_count as i64 || right < 0 || right >= right_count as i64 { return -1; }
        adjacency[left as usize * MAX_SIDE + right as usize] = true;
    }
    let mut pair_right = [-1i32; MAX_SIDE];
    let mut matching = 0i64;
    for left in 0..left_count {
        let mut seen_right = [false; MAX_SIDE];
        if try_augment(left, right_count, &adjacency, &mut seen_right, &mut pair_right) { matching += 1; }
    }
    matching
}
