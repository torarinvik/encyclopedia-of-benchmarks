const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 52;

#[derive(Clone, Copy, Default)]
struct Edge {
    u: usize,
    v: usize,
    weight: i64,
    original_id: usize,
}

fn edge_less(left: Edge, right: Edge) -> bool {
    (left.weight, left.original_id) < (right.weight, right.original_id)
}

fn find_root(parent: &mut [usize; MAX_VERTICES], start: usize) -> usize {
    let mut root = start;
    while parent[root] != root {
        root = parent[root];
    }
    let mut vertex = start;
    while parent[vertex] != vertex {
        let next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    root
}

fn splitmix64_next(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut value = *state;
    value = (value ^ (value >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    value = (value ^ (value >> 27)).wrapping_mul(0x94D049BB133111EB);
    value ^ (value >> 31)
}

fn boruvka_phase(
    vertex_count: &mut usize,
    edge_count: &mut usize,
    edges: &mut [Edge; MAX_EDGES],
) -> u64 {
    let mut selected = [false; MAX_EDGES];
    for vertex in 0..*vertex_count {
        let mut best = None;
        for edge_index in 0..*edge_count {
            let edge = edges[edge_index];
            if edge.u != vertex && edge.v != vertex {
                continue;
            }
            if best.map_or(true, |current| edge_less(edge, edges[current])) {
                best = Some(edge_index);
            }
        }
        if let Some(edge_index) = best {
            selected[edge_index] = true;
        }
    }

    let mut selected_mask = 0u64;
    let mut parent = [0usize; MAX_VERTICES];
    for vertex in 0..*vertex_count {
        parent[vertex] = vertex;
    }
    for edge_index in 0..*edge_count {
        if !selected[edge_index] {
            continue;
        }
        let edge = edges[edge_index];
        selected_mask |= 1u64 << edge.original_id;
        let left = find_root(&mut parent, edge.u);
        let right = find_root(&mut parent, edge.v);
        if left != right {
            parent[right] = left;
        }
    }

    let mut root_to_new = [-1i32; MAX_VERTICES];
    let mut remapped = [0usize; MAX_VERTICES];
    let mut new_vertex_count = 0usize;
    for vertex in 0..*vertex_count {
        let root = find_root(&mut parent, vertex);
        if root_to_new[root] < 0 {
            root_to_new[root] = new_vertex_count as i32;
            new_vertex_count += 1;
        }
        remapped[vertex] = root_to_new[root] as usize;
    }

    let mut reduced = [Edge::default(); MAX_EDGES];
    let mut reduced_count = 0usize;
    for edge_index in 0..*edge_count {
        let mut edge = edges[edge_index];
        let mut left = remapped[edge.u];
        let mut right = remapped[edge.v];
        if left == right {
            continue;
        }
        if left > right {
            core::mem::swap(&mut left, &mut right);
        }
        edge.u = left;
        edge.v = right;
        let mut parallel = None;
        for prior in 0..reduced_count {
            if reduced[prior].u == left && reduced[prior].v == right {
                parallel = Some(prior);
                break;
            }
        }
        if let Some(prior) = parallel {
            if edge_less(edge, reduced[prior]) {
                reduced[prior] = edge;
            }
        } else {
            reduced[reduced_count] = edge;
            reduced_count += 1;
        }
    }

    *vertex_count = new_vertex_count;
    *edge_count = reduced_count;
    *edges = reduced;
    selected_mask
}

fn path_maximum(
    edge_count: usize,
    edges: &[Edge; MAX_EDGES],
    forest_mask: u64,
    source: usize,
    target: usize,
) -> Option<(i64, usize)> {
    let mut parent_vertex = [-1i32; MAX_VERTICES];
    let mut parent_edge = [-1i32; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let (mut head, mut tail) = (0usize, 0usize);
    parent_vertex[source] = source as i32;
    queue[tail] = source;
    tail += 1;
    while head < tail && parent_vertex[target] < 0 {
        let current = queue[head];
        head += 1;
        for edge_index in 0..edge_count {
            let edge = edges[edge_index];
            if forest_mask & (1u64 << edge.original_id) == 0 {
                continue;
            }
            let next = if edge.u == current {
                Some(edge.v)
            } else if edge.v == current {
                Some(edge.u)
            } else {
                None
            };
            if let Some(next_vertex) = next {
                if parent_vertex[next_vertex] < 0 {
                    parent_vertex[next_vertex] = current as i32;
                    parent_edge[next_vertex] = edge_index as i32;
                    queue[tail] = next_vertex;
                    tail += 1;
                }
            }
        }
    }
    if parent_vertex[target] < 0 {
        return None;
    }

    let (mut max_weight, mut max_id) = (-1i64, 0usize);
    let mut current = target;
    while current != source {
        let edge_index = parent_edge[current] as usize;
        let edge = edges[edge_index];
        if edge.weight > max_weight || (edge.weight == max_weight && edge.original_id > max_id) {
            max_weight = edge.weight;
            max_id = edge.original_id;
        }
        current = parent_vertex[current] as usize;
    }
    Some((max_weight, max_id))
}

fn recursive_mst(
    initial_vertex_count: usize,
    initial_edge_count: usize,
    initial_edges: [Edge; MAX_EDGES],
    state: &mut u64,
) -> u64 {
    if initial_edge_count == 0 {
        return 0;
    }
    let mut vertex_count = initial_vertex_count;
    let mut edge_count = initial_edge_count;
    let mut edges = initial_edges;
    let mut selected_mask = 0u64;

    for _ in 0..2 {
        selected_mask |= boruvka_phase(&mut vertex_count, &mut edge_count, &mut edges);
        if edge_count == 0 {
            return selected_mask;
        }
    }

    for index in 1..edge_count {
        let edge = edges[index];
        let mut position = index;
        while position > 0 && edge_less(edge, edges[position - 1]) {
            edges[position] = edges[position - 1];
            position -= 1;
        }
        edges[position] = edge;
    }

    let mut sample_edges = [Edge::default(); MAX_EDGES];
    let mut sample_count = 0usize;
    for edge in edges[..edge_count].iter().copied() {
        if splitmix64_next(state) & 1 != 0 {
            sample_edges[sample_count] = edge;
            sample_count += 1;
        }
    }
    let forest_mask = recursive_mst(vertex_count, sample_count, sample_edges, state);

    let mut light_edges = [Edge::default(); MAX_EDGES];
    let mut light_count = 0usize;
    for edge in edges[..edge_count].iter().copied() {
        let in_forest = forest_mask & (1u64 << edge.original_id) != 0;
        let heavy = if in_forest {
            false
        } else if let Some((max_weight, max_id)) = path_maximum(
            edge_count,
            &edges,
            forest_mask,
            edge.u,
            edge.v,
        ) {
            edge.weight > max_weight || (edge.weight == max_weight && edge.original_id > max_id)
        } else {
            false
        };
        if !heavy {
            light_edges[light_count] = edge;
            light_count += 1;
        }
    }

    selected_mask | recursive_mst(vertex_count, light_count, light_edges, state)
}

#[no_mangle]
pub unsafe extern "C" fn kkt_recursive_mst(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = core::slice::from_raw_parts(input, length);
    let (vertex_value, edge_value, seed_value) = (values[0], values[1], values[2]);
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
        || seed_value < 0
    {
        return -1;
    }
    let (vertex_count, edge_count) = (vertex_value as usize, edge_value as usize);
    if length != 3 + 3 * edge_count {
        return -1;
    }

    let mut edges = [Edge::default(); MAX_EDGES];
    for edge_index in 0..edge_count {
        let (u_value, v_value, weight) = (
            values[3 + 3 * edge_index],
            values[4 + 3 * edge_index],
            values[5 + 3 * edge_index],
        );
        if u_value < 0
            || v_value <= u_value
            || v_value >= vertex_value
            || !(0..=255).contains(&weight)
        {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        for prior in 0..edge_index {
            if edges[prior].u == u && edges[prior].v == v {
                return -1;
            }
        }
        edges[edge_index] = Edge {
            u,
            v,
            weight,
            original_id: edge_index,
        };
    }

    let mut state = seed_value as u64;
    recursive_mst(vertex_count, edge_count, edges, &mut state) as i64
}
