const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

#[no_mangle]
pub extern "C" fn incremental_scc(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=MAX_VERTICES as i64).contains(&values[0]) || !(0..=MAX_EDGES as i64).contains(&values[1]) {
        return -1;
    }
    let vertex_count = values[0] as usize;
    let edge_count = values[1] as usize;
    if length != 2 + 2 * edge_count {
        return -1;
    }
    let mut edges = Vec::with_capacity(edge_count);
    for edge in 0..edge_count {
        let source = values[2 + 2 * edge];
        let destination = values[3 + 2 * edge];
        if !(0..vertex_count as i64).contains(&source) || !(0..vertex_count as i64).contains(&destination) {
            return -1;
        }
        edges.push((source as usize, destination as usize));
    }

    let mut reachable = [[false; MAX_VERTICES]; MAX_VERTICES];
    for vertex in 0..vertex_count {
        reachable[vertex][vertex] = true;
    }
    let mut checksum = 0_i64;
    for (step, &(source, destination)) in edges.iter().enumerate() {
        let mut predecessors = [false; MAX_VERTICES];
        let mut successors = [false; MAX_VERTICES];
        for vertex in 0..vertex_count {
            predecessors[vertex] = reachable[vertex][source];
            successors[vertex] = reachable[destination][vertex];
        }
        for first in 0..vertex_count {
            for second in 0..vertex_count {
                if predecessors[first] && successors[second] {
                    reachable[first][second] = true;
                }
            }
        }

        let mut assigned = [false; MAX_VERTICES];
        let mut component_count = 0_i64;
        for first in 0..vertex_count {
            if assigned[first] {
                continue;
            }
            component_count += 1;
            for vertex in first..vertex_count {
                if reachable[first][vertex] && reachable[vertex][first] {
                    assigned[vertex] = true;
                }
            }
        }
        checksum += (step as i64 + 1) * component_count;
    }
    checksum
}
