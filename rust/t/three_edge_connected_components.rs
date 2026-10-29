const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

#[derive(Clone, Copy)]
struct Edge {
    from: usize,
    to: usize,
}

fn refine_for_removal(
    edges: &[Edge; MAX_EDGES], vertex_count: usize, edge_count: usize,
    removed_first: isize, removed_second: isize,
    same: &mut [[bool; MAX_VERTICES]; MAX_VERTICES],
) {
    let mut component = [-1isize; MAX_VERTICES];
    let mut next_component = 0isize;
    let mut queue = [0usize; MAX_VERTICES];
    for start in 0..vertex_count {
        if component[start] >= 0 { continue; }
        let (mut head, mut tail) = (0usize, 0usize);
        component[start] = next_component;
        queue[tail] = start;
        tail += 1;
        while head < tail {
            let vertex = queue[head];
            head += 1;
            for edge_id in 0..edge_count {
                if edge_id as isize == removed_first || edge_id as isize == removed_second { continue; }
                let edge = edges[edge_id];
                let neighbor = if edge.from == vertex { Some(edge.to) }
                    else if edge.to == vertex { Some(edge.from) } else { None };
                if let Some(other) = neighbor {
                    if component[other] < 0 {
                        component[other] = next_component;
                        queue[tail] = other;
                        tail += 1;
                    }
                }
            }
        }
        next_component += 1;
    }
    for first in 0..vertex_count {
        for second in first + 1..vertex_count {
            if component[first] != component[second] {
                same[first][second] = false;
                same[second][first] = false;
            }
        }
    }
}

#[no_mangle]
pub extern "C" fn three_edge_connected_components(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    if !(1..=MAX_VERTICES as i64).contains(&packed[0]) || !(0..=MAX_EDGES as i64).contains(&packed[1]) { return -1; }
    let vertex_count = packed[0] as usize;
    let edge_count = packed[1] as usize;
    if length != 2 + 2 * edge_count { return -1; }

    let mut edges = [Edge { from: 0, to: 0 }; MAX_EDGES];
    for edge_id in 0..edge_count {
        let from = packed[2 + 2 * edge_id];
        let to = packed[3 + 2 * edge_id];
        if from < 0 || from >= vertex_count as i64 || to < 0 || to >= vertex_count as i64 { return -1; }
        edges[edge_id] = Edge { from: from as usize, to: to as usize };
    }

    let mut same = [[true; MAX_VERTICES]; MAX_VERTICES];
    refine_for_removal(&edges, vertex_count, edge_count, -1, -1, &mut same);
    for first in 0..edge_count {
        refine_for_removal(&edges, vertex_count, edge_count, first as isize, -1, &mut same);
        for second in first + 1..edge_count {
            refine_for_removal(&edges, vertex_count, edge_count,
                               first as isize, second as isize, &mut same);
        }
    }

    let mut labels = [-1i64; MAX_VERTICES];
    let mut next_label = 0i64;
    for first in 0..vertex_count {
        if labels[first] >= 0 { continue; }
        for vertex in first..vertex_count {
            if labels[vertex] < 0 && same[first][vertex] { labels[vertex] = next_label; }
        }
        next_label += 1;
    }
    let mut encoded = 0i64;
    let mut place = 1i64;
    for vertex in 0..vertex_count {
        encoded += labels[vertex] * place;
        place *= 8;
    }
    encoded
}
