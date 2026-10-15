use std::slice;

const MAX_VERTICES: usize = 256;
const MAX_EDGES: usize = 4096;
const INF: i64 = i64::MAX / 4;

#[no_mangle]
pub unsafe extern "C" fn a_star_search(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > 4 + MAX_VERTICES + 2 * MAX_EDGES {
        return -1;
    }
    let values = slice::from_raw_parts(input, length);
    let (vertex_value, edge_value, source_value, target_value) =
        (values[0], values[1], values[2], values[3]);
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
        || source_value < 0
        || source_value >= vertex_value
        || target_value < 0
        || target_value >= vertex_value
    {
        return -1;
    }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    let source = source_value as usize;
    let target = target_value as usize;
    if length != 4 + vertices + 2 * edges {
        return -1;
    }

    let mut heuristic = [0i64; MAX_VERTICES];
    let mut distance = [INF; MAX_VERTICES];
    let mut parent = [-1i64; MAX_VERTICES];
    let mut reversed = [0i64; MAX_VERTICES];
    let mut opened = [false; MAX_VERTICES];
    let mut closed = [false; MAX_VERTICES];
    for vertex in 0..vertices {
        heuristic[vertex] = values[4 + vertex];
        if !(0..=1_000_000_000).contains(&heuristic[vertex]) {
            return -1;
        }
    }
    if heuristic[target] != 0 {
        return -1;
    }
    let edge_offset = 4 + vertices;
    for edge in 0..edges {
        let origin = values[edge_offset + 2 * edge];
        let neighbor = values[edge_offset + 2 * edge + 1];
        if origin < 0
            || origin >= vertex_value
            || neighbor < 0
            || neighbor >= vertex_value
            || heuristic[origin as usize] > heuristic[neighbor as usize] + 1
        {
            return -1;
        }
    }

    distance[source] = 0;
    opened[source] = true;
    loop {
        let mut best = vertices;
        for vertex in 0..vertices {
            if !opened[vertex] {
                continue;
            }
            if best == vertices
                || distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best]
                || (distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best]
                    && (distance[vertex] < distance[best]
                        || (distance[vertex] == distance[best] && vertex < best)))
            {
                best = vertex;
            }
        }
        if best == vertices {
            break;
        }
        opened[best] = false;
        closed[best] = true;
        if best == target {
            break;
        }
        for edge in 0..edges {
            if values[edge_offset + 2 * edge] != best as i64 {
                continue;
            }
            let neighbor = values[edge_offset + 2 * edge + 1] as usize;
            if closed[neighbor] {
                continue;
            }
            let candidate = distance[best] + 1;
            if candidate < distance[neighbor] {
                distance[neighbor] = candidate;
                parent[neighbor] = best as i64;
                opened[neighbor] = true;
            }
        }
    }
    if distance[target] == INF {
        return 0;
    }

    let mut path_length = 0;
    let mut current = target as i64;
    while current >= 0 && path_length < vertices {
        reversed[path_length] = current;
        path_length += 1;
        if current as usize == source {
            break;
        }
        current = parent[current as usize];
    }
    if path_length == 0
        || reversed[path_length - 1] as usize != source
        || path_length - 1 > 30
    {
        return -1;
    }
    if output_capacity < path_length || output.is_null() {
        return -2;
    }
    for index in 0..path_length {
        output.add(index).write(reversed[path_length - 1 - index] as u8);
    }
    path_length as i64
}
