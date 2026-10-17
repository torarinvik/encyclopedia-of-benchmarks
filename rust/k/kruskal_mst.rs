const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = MAX_VERTICES * (MAX_VERTICES - 1) / 2;
const MAX_VALID_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES;
const MAX_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;
const WEIGHT_MIN: i64 = -1_000_000;
const WEIGHT_MAX: i64 = 1_000_000;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

#[derive(Clone, Copy, Default)]
struct Edge {
    left: usize,
    right: usize,
    weight: i32,
}

fn sift_down(edges: &mut [Edge; MAX_EDGES], root_arg: usize, end_exclusive: usize) {
    let mut root = root_arg;
    while root * 2 + 1 < end_exclusive {
        let mut child = root * 2 + 1;
        if child + 1 < end_exclusive && edges[child].weight < edges[child + 1].weight {
            child += 1;
        }
        if edges[root].weight >= edges[child].weight {
            return;
        }
        edges.swap(root, child);
        root = child;
    }
}

fn sort_edges(edges: &mut [Edge; MAX_EDGES], count: usize) {
    let mut start = count / 2;
    while start > 0 {
        start -= 1;
        sift_down(edges, start, count);
    }
    let mut end_exclusive = count;
    while end_exclusive > 1 {
        end_exclusive -= 1;
        edges.swap(0, end_exclusive);
        sift_down(edges, 0, end_exclusive);
    }
}

fn find_root(parent: &mut [usize; MAX_VERTICES], vertex_arg: usize) -> usize {
    let mut root = vertex_arg;
    while parent[root] != root {
        root = parent[root];
    }
    let mut vertex = vertex_arg;
    while parent[vertex] != vertex {
        let next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    root
}

fn union_sets(
    parent: &mut [usize; MAX_VERTICES],
    ranks: &mut [usize; MAX_VERTICES],
    left: usize,
    right: usize,
) -> bool {
    let left_root = find_root(parent, left);
    let right_root = find_root(parent, right);
    if left_root == right_root {
        return false;
    }
    if ranks[left_root] < ranks[right_root] {
        parent[left_root] = right_root;
    } else {
        parent[right_root] = left_root;
        if ranks[left_root] == ranks[right_root] {
            ranks[left_root] += 1;
        }
    }
    true
}

fn hash_byte(hash: u64, byte: u8) -> u64 {
    (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME)
}

fn hash_u16(mut hash: u64, value: u16) -> u64 {
    for byte in value.to_le_bytes() {
        hash = hash_byte(hash, byte);
    }
    hash
}

fn hash_i32(mut hash: u64, value: i32) -> u64 {
    for byte in value.to_le_bytes() {
        hash = hash_byte(hash, byte);
    }
    hash
}

fn hash_i64(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() {
        hash = hash_byte(hash, byte);
    }
    hash
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH {
        return Err(());
    }
    let vertex_count64 = input[0];
    let edge_count64 = input[1];
    if !(1..=MAX_VERTICES as i64).contains(&vertex_count64)
        || !(0..=MAX_EDGES as i64).contains(&edge_count64)
    {
        return Err(());
    }
    let vertex_count = vertex_count64 as usize;
    let edge_count = edge_count64 as usize;
    if input.len() != 2 + 3 * edge_count || input.len() > MAX_VALID_INPUT_LENGTH {
        return Err(());
    }
    let maximum_for_graph = vertex_count * (vertex_count - 1) / 2;
    if edge_count > maximum_for_graph
        || (vertex_count == 1 && edge_count != 0)
        || (vertex_count > 1 && edge_count < vertex_count - 1)
    {
        return Err(());
    }

    let mut edges = [Edge::default(); MAX_EDGES];
    let mut seen_pairs = [[false; MAX_VERTICES]; MAX_VERTICES];
    for index in 0..edge_count {
        let offset = 2 + 3 * index;
        let raw_left = input[offset];
        let raw_right = input[offset + 1];
        let raw_weight = input[offset + 2];
        if raw_left < 0
            || raw_left >= vertex_count64
            || raw_right < 0
            || raw_right >= vertex_count64
            || raw_left == raw_right
            || !(WEIGHT_MIN..=WEIGHT_MAX).contains(&raw_weight)
        {
            return Err(());
        }
        let left = raw_left as usize;
        let right = raw_right as usize;
        let lower = left.min(right);
        let upper = left.max(right);
        if seen_pairs[lower][upper] {
            return Err(());
        }
        seen_pairs[lower][upper] = true;
        edges[index] = Edge {
            left: lower,
            right: upper,
            weight: raw_weight as i32,
        };
    }

    sort_edges(&mut edges, edge_count);
    if edge_count > 1 {
        for index in 1..edge_count {
            if edges[index - 1].weight == edges[index].weight {
                return Err(());
            }
        }
    }

    let mut parent = [0usize; MAX_VERTICES];
    let mut ranks = [0usize; MAX_VERTICES];
    for vertex in 0..vertex_count {
        parent[vertex] = vertex;
    }
    let mut accepted = [Edge::default(); MAX_VERTICES - 1];
    let mut accepted_count = 0usize;
    let mut total_weight = 0i64;
    for edge in edges.iter().take(edge_count) {
        if accepted_count == vertex_count - 1 {
            break;
        }
        if union_sets(&mut parent, &mut ranks, edge.left, edge.right) {
            accepted[accepted_count] = *edge;
            accepted_count += 1;
            total_weight += i64::from(edge.weight);
        }
    }
    if accepted_count != vertex_count - 1 {
        return Err(());
    }

    let mut hash = FNV_OFFSET;
    hash = hash_u16(hash, vertex_count as u16);
    hash = hash_u16(hash, accepted_count as u16);
    for edge in accepted.iter().take(accepted_count) {
        hash = hash_u16(hash, edge.left as u16);
        hash = hash_u16(hash, edge.right as u16);
        hash = hash_i32(hash, edge.weight);
    }
    hash = hash_i64(hash, total_weight);
    Ok((hash & 0x7fff_ffff_ffff_ffff) as i64)
}

#[no_mangle]
pub unsafe extern "C" fn kruskal_mst(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
