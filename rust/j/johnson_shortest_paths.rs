/// Bounded Johnson all-pairs shortest paths for the pinned R contract.
const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 770;
const MAX_QUEUE: usize = MAX_EDGES + 1;
const UNREACHABLE_SENTINEL: i64 = 1i64 << 62;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn fnv_word(mut hash: u64, value: i64) -> u64 {
    let bits = value as u64;
    for byte in 0..8 {
        hash ^= (bits >> (8 * byte)) & 0xff;
        hash = hash.wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn johnson_shortest_paths(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let vertex_value = input[0];
    let edge_value = input[1];
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
    {
        return -1;
    }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    if length != 2 + 3 * edges {
        return -1;
    }

    let mut edge_from = [0usize; MAX_EDGES];
    let mut edge_to = [0usize; MAX_EDGES];
    let mut edge_weight = [0i64; MAX_EDGES];
    for edge in 0..edges {
        let from = input[2 + 3 * edge];
        let to = input[3 + 3 * edge];
        let weight = input[4 + 3 * edge];
        if !(1..=vertex_value).contains(&from)
            || !(1..=vertex_value).contains(&to)
            || !(-32..=32).contains(&weight)
        {
            return -1;
        }
        edge_from[edge] = (from - 1) as usize;
        edge_to[edge] = (to - 1) as usize;
        edge_weight[edge] = weight;
    }

    let mut potential = [0i64; MAX_VERTICES];
    for _iteration in 1..vertices {
        let mut updated = false;
        for edge in 0..edges {
            let from = edge_from[edge];
            let to = edge_to[edge];
            let candidate = potential[from] + edge_weight[edge];
            if candidate < potential[to] {
                potential[to] = candidate;
                updated = true;
            }
        }
        if !updated {
            break;
        }
    }
    for edge in 0..edges {
        if potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]] {
            return -1;
        }
    }

    let mut result = FNV_OFFSET_BASIS;
    for source in 0..vertices {
        let mut distance = [i64::MAX; MAX_VERTICES];
        let mut visited = [false; MAX_VERTICES];
        distance[source] = 0;
        let mut queue_vertices = [0usize; MAX_QUEUE];
        let mut queue_distances = [0i64; MAX_QUEUE];
        let mut queue_length = 1usize;
        queue_vertices[0] = source;
        queue_distances[0] = 0;

        while queue_length > 0 {
            let mut minimum = 0usize;
            for index in 1..queue_length {
                if queue_distances[index] < queue_distances[minimum] {
                    minimum = index;
                }
            }
            let current = queue_vertices[minimum];
            for index in minimum + 1..queue_length {
                queue_vertices[index - 1] = queue_vertices[index];
                queue_distances[index - 1] = queue_distances[index];
            }
            queue_length -= 1;
            if visited[current] {
                continue;
            }
            visited[current] = true;

            for edge in 0..edges {
                if edge_from[edge] != current {
                    continue;
                }
                let next = edge_to[edge];
                let reweighted = edge_weight[edge] + potential[current] - potential[next];
                let candidate = distance[current] + reweighted;
                if !visited[next] && candidate < distance[next] {
                    distance[next] = candidate;
                    queue_vertices[queue_length] = next;
                    queue_distances[queue_length] = candidate;
                    queue_length += 1;
                }
            }
        }

        for destination in 0..vertices {
            let output = if distance[destination] == i64::MAX {
                UNREACHABLE_SENTINEL
            } else {
                distance[destination] - potential[source] + potential[destination]
            };
            result = fnv_word(result, output);
        }
    }
    (result & i64::MAX as u64) as i64
}
