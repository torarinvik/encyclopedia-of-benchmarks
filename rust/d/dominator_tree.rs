const MAX_VERTEX_COUNT: usize = 63;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 3 + 2 * MAX_EDGE_COUNT as usize;

fn count_bits(mut value: u64) -> usize {
    let mut count = 0;
    while value != 0 {
        value &= value - 1;
        count += 1;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn dominator_tree(input: *const i64, length: usize,
                                           output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let vertex_value = *input;
    let root_value = *input.add(1);
    let edge_value = *input.add(2);
    if !(1..=MAX_VERTEX_COUNT as i64).contains(&vertex_value) || root_value < 0 ||
        root_value >= vertex_value || !(0..=MAX_EDGE_COUNT).contains(&edge_value) { return -1; }
    let vertex_count = vertex_value as usize;
    let root = root_value as usize;
    let edge_count = edge_value as usize;
    if length != 3 + 2 * edge_count { return -1; }

    let mut outgoing = [0u64; MAX_VERTEX_COUNT];
    for edge in 0..edge_count {
        let from_value = *input.add(3 + 2 * edge);
        let to_value = *input.add(4 + 2 * edge);
        if from_value < 0 || to_value < 0 || from_value >= vertex_count as i64 ||
            to_value >= vertex_count as i64 { return -1; }
        outgoing[from_value as usize] |= 1u64 << to_value as usize;
    }

    let mut reachable = 1u64 << root;
    let mut frontier = reachable;
    while frontier != 0 {
        let mut discovered = 0u64;
        for vertex in 0..vertex_count {
            if frontier & (1u64 << vertex) != 0 { discovered |= outgoing[vertex]; }
        }
        discovered &= !reachable;
        reachable |= discovered;
        frontier = discovered;
    }

    let mut dominators = [0u64; MAX_VERTEX_COUNT];
    dominators[root] = 1u64 << root;
    for vertex in 0..vertex_count {
        if reachable & (1u64 << vertex) != 0 && vertex != root { dominators[vertex] = reachable; }
    }
    loop {
        let mut changed = false;
        for vertex in 0..vertex_count {
            let vertex_bit = 1u64 << vertex;
            if reachable & vertex_bit == 0 || vertex == root { continue; }
            let mut common = reachable;
            for predecessor in 0..vertex_count {
                if reachable & (1u64 << predecessor) != 0 && outgoing[predecessor] & vertex_bit != 0 {
                    common &= dominators[predecessor];
                }
            }
            let updated = common | vertex_bit;
            if updated != dominators[vertex] {
                dominators[vertex] = updated;
                changed = true;
            }
        }
        if !changed { break; }
    }

    if output.is_null() || output_capacity < vertex_count { return -2; }
    for vertex in 0..vertex_count {
        let vertex_bit = 1u64 << vertex;
        if reachable & vertex_bit == 0 {
            *output.add(vertex) = u8::MAX;
        } else if vertex == root {
            *output.add(vertex) = root as u8;
        } else {
            let strict = dominators[vertex] & !vertex_bit;
            let mut best = root;
            let mut best_depth = 0;
            for candidate in 0..vertex_count {
                if strict & (1u64 << candidate) == 0 { continue; }
                let depth = count_bits(dominators[candidate]);
                if depth > best_depth {
                    best = candidate;
                    best_depth = depth;
                }
            }
            *output.add(vertex) = best as u8;
        }
    }
    vertex_count as i64
}
