const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 4 + 3 * MAX_EDGES + 1;

const FREE_TREE: u8 = 0;
const SOURCE_TREE: u8 = 1;
const SINK_TREE: u8 = 2;

struct FlowState {
    n: usize,
    source: usize,
    sink: usize,
    residual: [[i64; MAX_VERTICES]; MAX_VERTICES],
    tree: [u8; MAX_VERTICES],
    parent: [i32; MAX_VERTICES],
    active_queue: [usize; MAX_VERTICES],
    active_head: usize,
    active_tail: usize,
    active_count: usize,
    is_active: [bool; MAX_VERTICES],
    orphan_queue: [usize; MAX_VERTICES],
    orphan_head: usize,
    orphan_tail: usize,
    orphan_count: usize,
    is_orphan: [bool; MAX_VERTICES],
    total_flow: i64,
}

fn tree_capacity(state: &FlowState, kind: u8, parent_vertex: usize, child_vertex: usize) -> i64 {
    if kind == SOURCE_TREE {
        state.residual[parent_vertex][child_vertex]
    } else {
        state.residual[child_vertex][parent_vertex]
    }
}

fn enqueue_active(state: &mut FlowState, vertex: usize) {
    if state.is_active[vertex] {
        return;
    }
    if state.active_tail >= MAX_VERTICES {
        for offset in 0..state.active_count {
            state.active_queue[offset] = state.active_queue[state.active_head + offset];
        }
        state.active_head = 0;
        state.active_tail = state.active_count;
    }
    state.active_queue[state.active_tail] = vertex;
    state.active_tail += 1;
    state.active_count += 1;
    state.is_active[vertex] = true;
}

fn dequeue_active(state: &mut FlowState) -> usize {
    let vertex = state.active_queue[state.active_head];
    state.active_head += 1;
    state.active_count -= 1;
    state.is_active[vertex] = false;
    if state.active_count == 0 {
        state.active_head = 0;
        state.active_tail = 0;
    }
    vertex
}

fn remove_active(state: &mut FlowState, vertex: usize) {
    if !state.is_active[vertex] {
        return;
    }
    let mut index = state.active_head;
    while index < state.active_tail {
        if state.active_queue[index] == vertex {
            let mut shift = index;
            while shift + 1 < state.active_tail {
                state.active_queue[shift] = state.active_queue[shift + 1];
                shift += 1;
            }
            state.active_tail -= 1;
            state.active_count -= 1;
            state.is_active[vertex] = false;
            if state.active_count == 0 {
                state.active_head = 0;
                state.active_tail = 0;
            }
            return;
        }
        index += 1;
    }
}

fn enqueue_orphan(state: &mut FlowState, vertex: usize) {
    if state.is_orphan[vertex] {
        return;
    }
    if state.orphan_tail >= MAX_VERTICES {
        for offset in 0..state.orphan_count {
            state.orphan_queue[offset] = state.orphan_queue[state.orphan_head + offset];
        }
        state.orphan_head = 0;
        state.orphan_tail = state.orphan_count;
    }
    state.orphan_queue[state.orphan_tail] = vertex;
    state.orphan_tail += 1;
    state.orphan_count += 1;
    state.is_orphan[vertex] = true;
}

fn dequeue_orphan(state: &mut FlowState) -> usize {
    let vertex = state.orphan_queue[state.orphan_head];
    state.orphan_head += 1;
    state.orphan_count -= 1;
    state.is_orphan[vertex] = false;
    if state.orphan_count == 0 {
        state.orphan_head = 0;
        state.orphan_tail = 0;
    }
    vertex
}

fn has_terminal_origin(state: &FlowState, vertex: usize, kind: u8, blocked: usize) -> bool {
    let root = if kind == SOURCE_TREE { state.source } else { state.sink };
    let mut seen = [false; MAX_VERTICES];
    let mut current = vertex;
    loop {
        if current == blocked || current >= state.n || seen[current] || state.tree[current] != kind {
            return false;
        }
        if current == root {
            return true;
        }
        seen[current] = true;
        let next_value = state.parent[current];
        if next_value < 0 || next_value as usize >= state.n {
            return false;
        }
        let next_vertex = next_value as usize;
        if tree_capacity(state, kind, next_vertex, current) <= 0 {
            return false;
        }
        current = next_vertex;
    }
}

fn solve(n: usize, source: usize, sink: usize, values: &[i64], edge_count: usize) -> i64 {
    let mut state = FlowState {
        n,
        source,
        sink,
        residual: [[0; MAX_VERTICES]; MAX_VERTICES],
        tree: [FREE_TREE; MAX_VERTICES],
        parent: [-1; MAX_VERTICES],
        active_queue: [0; MAX_VERTICES],
        active_head: 0,
        active_tail: 0,
        active_count: 0,
        is_active: [false; MAX_VERTICES],
        orphan_queue: [0; MAX_VERTICES],
        orphan_head: 0,
        orphan_tail: 0,
        orphan_count: 0,
        is_orphan: [false; MAX_VERTICES],
        total_flow: 0,
    };
    for edge_index in 0..edge_count {
        let from_vertex = values[4 + 3 * edge_index] as usize;
        let to_vertex = values[5 + 3 * edge_index] as usize;
        let capacity = values[6 + 3 * edge_index];
        state.residual[from_vertex][to_vertex] += capacity;
    }

    state.tree[source] = SOURCE_TREE;
    state.tree[sink] = SINK_TREE;
    enqueue_active(&mut state, source);
    enqueue_active(&mut state, sink);

    while state.active_count > 0 {
        let mut bridge_source = None;
        let mut bridge_sink = None;
        while state.active_count > 0 && bridge_source.is_none() {
            let vertex = dequeue_active(&mut state);
            let kind = state.tree[vertex];
            for neighbor in 0..n {
                if tree_capacity(&state, kind, vertex, neighbor) <= 0 {
                    continue;
                }
                if state.tree[neighbor] == FREE_TREE {
                    state.tree[neighbor] = kind;
                    state.parent[neighbor] = vertex as i32;
                    enqueue_active(&mut state, neighbor);
                } else if state.tree[neighbor] != kind {
                    if kind == SOURCE_TREE {
                        bridge_source = Some(vertex);
                        bridge_sink = Some(neighbor);
                    } else {
                        bridge_source = Some(neighbor);
                        bridge_sink = Some(vertex);
                    }
                    enqueue_active(&mut state, vertex);
                    break;
                }
            }
        }
        let Some(bridge_source) = bridge_source else { break };
        let Some(bridge_sink) = bridge_sink else { return -1 };

        let mut path_from = [0usize; MAX_VERTICES];
        let mut path_to = [0usize; MAX_VERTICES];
        let mut path_length = 0usize;
        let mut reversed_source = [0usize; MAX_VERTICES];
        let mut source_length = 0usize;
        let mut current = bridge_source;
        while current != source {
            if source_length >= MAX_VERTICES {
                return -1;
            }
            reversed_source[source_length] = current;
            source_length += 1;
            let parent_value = state.parent[current];
            if parent_value < 0 || parent_value as usize >= n {
                return -1;
            }
            current = parent_value as usize;
        }
        while source_length > 0 {
            source_length -= 1;
            let child = reversed_source[source_length];
            let parent_value = state.parent[child];
            if parent_value < 0 || parent_value as usize >= n {
                return -1;
            }
            path_from[path_length] = parent_value as usize;
            path_to[path_length] = child;
            path_length += 1;
        }
        path_from[path_length] = bridge_source;
        path_to[path_length] = bridge_sink;
        path_length += 1;
        current = bridge_sink;
        while current != sink {
            if path_length >= MAX_VERTICES {
                return -1;
            }
            let parent_value = state.parent[current];
            if parent_value < 0 || parent_value as usize >= n {
                return -1;
            }
            let next_vertex = parent_value as usize;
            path_from[path_length] = current;
            path_to[path_length] = next_vertex;
            path_length += 1;
            current = next_vertex;
        }
        if path_length == 0 {
            return -1;
        }

        let mut bottleneck = state.residual[path_from[0]][path_to[0]];
        for path_index in 1..path_length {
            bottleneck = bottleneck.min(state.residual[path_from[path_index]][path_to[path_index]]);
        }
        if bottleneck <= 0 {
            return -1;
        }
        for path_index in 0..path_length {
            let from_vertex = path_from[path_index];
            let to_vertex = path_to[path_index];
            state.residual[from_vertex][to_vertex] -= bottleneck;
            state.residual[to_vertex][from_vertex] += bottleneck;
        }
        state.total_flow += bottleneck;

        for path_index in 0..path_length {
            let from_vertex = path_from[path_index];
            let to_vertex = path_to[path_index];
            if state.residual[from_vertex][to_vertex] != 0 {
                continue;
            }
            if state.tree[from_vertex] == SOURCE_TREE
                && state.tree[to_vertex] == SOURCE_TREE
                && state.parent[to_vertex] == from_vertex as i32
            {
                state.parent[to_vertex] = -1;
                enqueue_orphan(&mut state, to_vertex);
            } else if state.tree[from_vertex] == SINK_TREE
                && state.tree[to_vertex] == SINK_TREE
                && state.parent[from_vertex] == to_vertex as i32
            {
                state.parent[from_vertex] = -1;
                enqueue_orphan(&mut state, from_vertex);
            }
        }

        while state.orphan_count > 0 {
            let orphan = dequeue_orphan(&mut state);
            let kind = state.tree[orphan];
            if kind == FREE_TREE {
                continue;
            }
            let mut replacement = None;
            for candidate in 0..n {
                if candidate == orphan || state.tree[candidate] != kind {
                    continue;
                }
                if tree_capacity(&state, kind, candidate, orphan) <= 0 {
                    continue;
                }
                if has_terminal_origin(&state, candidate, kind, orphan) {
                    replacement = Some(candidate);
                    break;
                }
            }
            if let Some(replacement) = replacement {
                state.parent[orphan] = replacement as i32;
                continue;
            }

            for neighbor in 0..n {
                if state.tree[neighbor] != kind {
                    continue;
                }
                if tree_capacity(&state, kind, neighbor, orphan) > 0 {
                    enqueue_active(&mut state, neighbor);
                }
                if state.parent[neighbor] == orphan as i32 {
                    state.parent[neighbor] = -1;
                    enqueue_orphan(&mut state, neighbor);
                }
            }
            state.tree[orphan] = FREE_TREE;
            state.parent[orphan] = -1;
            remove_active(&mut state, orphan);
        }
    }
    state.total_flow
}

#[no_mangle]
pub unsafe extern "C" fn boykov_kolmogorov_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let (n_value, edge_value, source_value, sink_value) = (values[0], values[1], values[2], values[3]);
    if !(2..=MAX_VERTICES as i64).contains(&n_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let edge_count = edge_value as usize;
    if length != 4 + 3 * edge_count
        || source_value < 0 || source_value >= n_value
        || sink_value < 0 || sink_value >= n_value
        || source_value == sink_value
    {
        return -1;
    }
    for edge_index in 0..edge_count {
        let from = values[4 + 3 * edge_index];
        let to = values[5 + 3 * edge_index];
        let capacity = values[6 + 3 * edge_index];
        if from < 0 || from >= n_value || to < 0 || to >= n_value
            || from == to || !(0..=15).contains(&capacity)
        {
            return -1;
        }
    }
    solve(n, source_value as usize, sink_value as usize, values, edge_count)
}
