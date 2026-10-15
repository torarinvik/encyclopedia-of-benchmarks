/// Hopcroft-Karp maximum cardinality matching for a bounded bipartite graph.
const MAX_SIDE: usize = 64;
const MAX_EDGES: usize = MAX_SIDE * MAX_SIDE;
const INF_DISTANCE: i32 = 1_000_000;

fn dfs_augment(left: usize, right_count: usize, adjacency: &[bool], distance: &mut [i32; MAX_SIDE],
               nil_distance: i32, pair_left: &mut [i32; MAX_SIDE],
               pair_right: &mut [i32; MAX_SIDE]) -> bool {
    for right in 0..right_count {
        if !adjacency[left * MAX_SIDE + right] { continue; }
        let mate = pair_right[right];
        if mate < 0 {
            if distance[left] + 1 != nil_distance { continue; }
            pair_left[left] = right as i32;
            pair_right[right] = left as i32;
            return true;
        }
        let mate = mate as usize;
        if distance[mate] == distance[left] + 1 &&
            dfs_augment(mate, right_count, adjacency, distance, nil_distance, pair_left, pair_right) {
            pair_left[left] = right as i32;
            pair_right[right] = left as i32;
            return true;
        }
    }
    distance[left] = INF_DISTANCE;
    false
}

fn bfs_layers(left_count: usize, right_count: usize, adjacency: &[bool], pair_right: &[i32; MAX_SIDE],
              distance: &mut [i32; MAX_SIDE]) -> i32 {
    let mut queue = [0usize; MAX_SIDE];
    let (mut head, mut tail) = (0usize, 0usize);
    for left in 0..left_count {
        if distance[left] == 0 { queue[tail] = left; tail += 1; }
    }
    let mut nil_distance = INF_DISTANCE;
    while head < tail {
        let left = queue[head]; head += 1;
        if distance[left] + 1 > nil_distance { continue; }
        for right in 0..right_count {
            if !adjacency[left * MAX_SIDE + right] { continue; }
            let mate = pair_right[right];
            if mate < 0 {
                nil_distance = nil_distance.min(distance[left] + 1);
            } else {
                let mate = mate as usize;
                if distance[mate] < 0 {
                    distance[mate] = distance[left] + 1;
                    queue[tail] = mate; tail += 1;
                }
            }
        }
    }
    nil_distance
}

#[no_mangle]
pub extern "C" fn hopcroft_karp_cardinality(input: *const i64, length: usize) -> i64 {
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
    let mut pair_left = [-1i32; MAX_SIDE];
    let mut pair_right = [-1i32; MAX_SIDE];
    let mut distance = [-1i32; MAX_SIDE];
    let mut matching = 0i64;
    loop {
        for left in 0..left_count { distance[left] = if pair_left[left] < 0 { 0 } else { -1 }; }
        let nil_distance = bfs_layers(left_count, right_count, &adjacency, &pair_right, &mut distance);
        if nil_distance == INF_DISTANCE { break; }
        for left in 0..left_count {
            if pair_left[left] < 0 && dfs_augment(left, right_count, &adjacency, &mut distance,
                                                  nil_distance, &mut pair_left, &mut pair_right) {
                matching += 1;
            }
        }
    }
    matching
}
