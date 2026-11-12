const MAX_VERTICES: usize = 16;
const MAX_EVENTS: usize = 32;
const MAX_INPUT_VALUES: usize = 2 + 4 * MAX_EVENTS + 1;
const TREE_NODES: usize = 4 * MAX_EVENTS + 8;

fn find_root(parent: &[usize; MAX_VERTICES], mut vertex: usize) -> usize {
    while parent[vertex] != vertex {
        vertex = parent[vertex];
    }
    vertex
}

fn add_interval(
    node: usize,
    left: usize,
    right: usize,
    query_left: usize,
    query_right: usize,
    edge_id: usize,
    bucket_count: &mut [usize; TREE_NODES],
    buckets: &mut [[usize; MAX_EVENTS]; TREE_NODES],
) {
    if query_left <= left && right <= query_right {
        buckets[node][bucket_count[node]] = edge_id;
        bucket_count[node] += 1;
        return;
    }
    let middle = left + (right - left) / 2;
    if query_left < middle {
        add_interval(2 * node, left, middle, query_left, query_right, edge_id,
                     bucket_count, buckets);
    }
    if query_right > middle {
        add_interval(2 * node + 1, middle, right, query_left, query_right,
                     edge_id, bucket_count, buckets);
    }
}

fn unite(
    left: usize,
    right: usize,
    parent: &mut [usize; MAX_VERTICES],
    set_size: &mut [usize; MAX_VERTICES],
    history_child: &mut [usize; MAX_VERTICES],
    history_root: &mut [usize; MAX_VERTICES],
    history_size: &mut [usize; MAX_VERTICES],
    history_count: &mut usize,
) {
    let mut root_left = find_root(parent, left);
    let mut root_right = find_root(parent, right);
    if root_left == root_right {
        return;
    }
    if set_size[root_left] > set_size[root_right] {
        core::mem::swap(&mut root_left, &mut root_right);
    }
    history_child[*history_count] = root_left;
    history_root[*history_count] = root_right;
    history_size[*history_count] = set_size[root_right];
    *history_count += 1;
    parent[root_left] = root_right;
    set_size[root_right] += set_size[root_left];
}

fn rollback_to(
    checkpoint: usize,
    parent: &mut [usize; MAX_VERTICES],
    set_size: &mut [usize; MAX_VERTICES],
    history_child: &[usize; MAX_VERTICES],
    history_root: &[usize; MAX_VERTICES],
    history_size: &[usize; MAX_VERTICES],
    history_count: &mut usize,
) {
    while *history_count > checkpoint {
        *history_count -= 1;
        let child = history_child[*history_count];
        let root = history_root[*history_count];
        parent[child] = child;
        set_size[root] = history_size[*history_count];
    }
}

fn solve_time_tree(
    node: usize,
    left: usize,
    right: usize,
    operation: &[i64; MAX_EVENTS],
    first: &[i64; MAX_EVENTS],
    second: &[i64; MAX_EVENTS],
    edge_left: &[i64; MAX_EVENTS],
    edge_right: &[i64; MAX_EVENTS],
    bucket_count: &[usize; TREE_NODES],
    buckets: &[[usize; MAX_EVENTS]; TREE_NODES],
    parent: &mut [usize; MAX_VERTICES],
    set_size: &mut [usize; MAX_VERTICES],
    history_child: &mut [usize; MAX_VERTICES],
    history_root: &mut [usize; MAX_VERTICES],
    history_size: &mut [usize; MAX_VERTICES],
    history_count: &mut usize,
    answer: &mut [i64; MAX_EVENTS],
) {
    let checkpoint = *history_count;
    for entry in 0..bucket_count[node] {
        let edge_id = buckets[node][entry];
        unite(edge_left[edge_id] as usize, edge_right[edge_id] as usize,
              parent, set_size, history_child, history_root, history_size,
              history_count);
    }
    if right - left == 1 {
        if operation[left] == 2 {
            answer[left] = if find_root(parent, first[left] as usize) ==
                find_root(parent, second[left] as usize) { 1 } else { 0 };
        }
    } else {
        let middle = left + (right - left) / 2;
        solve_time_tree(2 * node, left, middle, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            history_child, history_root, history_size, history_count, answer);
        solve_time_tree(2 * node + 1, middle, right, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            history_child, history_root, history_size, history_count, answer);
    }
    rollback_to(checkpoint, parent, set_size, history_child, history_root,
                history_size, history_count);
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn offline_dynamic_connectivity(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    if *input < 1 || *input > MAX_VERTICES as i64 || *input.add(1) < 0 ||
        *input.add(1) > MAX_EVENTS as i64 {
        return -1;
    }
    let vertex_count = *input as usize;
    let event_count = *input.add(1) as usize;
    if length != 2 + 4 * event_count {
        return -1;
    }

    let mut operation = [0i64; MAX_EVENTS];
    let mut first = [0i64; MAX_EVENTS];
    let mut second = [0i64; MAX_EVENTS];
    let mut edge_left = [0i64; MAX_EVENTS];
    let mut edge_right = [0i64; MAX_EVENTS];
    let mut start_time = [0usize; MAX_EVENTS];
    let mut used_id = [false; MAX_EVENTS];
    let mut active = [false; MAX_EVENTS];
    let mut query_count = 0usize;
    for time in 0..event_count {
        let offset = 2 + 4 * time;
        operation[time] = *input.add(offset);
        first[time] = *input.add(offset + 1);
        second[time] = *input.add(offset + 2);
        let third = *input.add(offset + 3);
        if operation[time] == 0 {
            let edge_id = first[time];
            if edge_id < 0 || edge_id >= MAX_EVENTS as i64 || second[time] < 0 ||
                second[time] >= vertex_count as i64 || third < 0 ||
                third >= vertex_count as i64 || used_id[edge_id as usize] {
                return -1;
            }
            let id = edge_id as usize;
            used_id[id] = true;
            active[id] = true;
            start_time[id] = time;
            edge_left[id] = second[time];
            edge_right[id] = third;
        } else if operation[time] == 1 {
            let edge_id = first[time];
            if edge_id < 0 || edge_id >= MAX_EVENTS as i64 ||
                !active[edge_id as usize] || second[time] != 0 || third != 0 {
                return -1;
            }
            active[edge_id as usize] = false;
        } else if operation[time] == 2 {
            if first[time] < 0 || first[time] >= vertex_count as i64 ||
                second[time] < 0 || second[time] >= vertex_count as i64 || third != 0 {
                return -1;
            }
            query_count += 1;
        } else {
            return -1;
        }
    }

    let required = 8 * query_count;
    if output.is_null() || capacity < required {
        return -2;
    }
    let mut bucket_count = [0usize; TREE_NODES];
    let mut buckets = [[0usize; MAX_EVENTS]; TREE_NODES];
    for edge_id in 0..MAX_EVENTS {
        if !used_id[edge_id] {
            continue;
        }
        let mut end_time = event_count;
        if !active[edge_id] {
            for time in start_time[edge_id] + 1..event_count {
                if operation[time] == 1 && first[time] == edge_id as i64 {
                    end_time = time;
                    break;
                }
            }
        }
        if start_time[edge_id] < end_time && event_count != 0 {
            add_interval(1, 0, event_count, start_time[edge_id], end_time,
                         edge_id, &mut bucket_count, &mut buckets);
        }
    }

    let mut parent = [0usize; MAX_VERTICES];
    let mut set_size = [0usize; MAX_VERTICES];
    for vertex in 0..vertex_count {
        parent[vertex] = vertex;
        set_size[vertex] = 1;
    }
    let mut history_child = [0usize; MAX_VERTICES];
    let mut history_root = [0usize; MAX_VERTICES];
    let mut history_size = [0usize; MAX_VERTICES];
    let mut history_count = 0usize;
    let mut answer = [0i64; MAX_EVENTS];
    if event_count != 0 {
        solve_time_tree(1, 0, event_count, &operation, &first, &second,
            &edge_left, &edge_right, &bucket_count, &buckets, &mut parent,
            &mut set_size, &mut history_child, &mut history_root,
            &mut history_size, &mut history_count, &mut answer);
    }

    let mut written = 0usize;
    for time in 0..event_count {
        if operation[time] == 2 {
            store_i64_le(output, written, answer[time]);
            written += 8;
        }
    }
    written as i64
}
