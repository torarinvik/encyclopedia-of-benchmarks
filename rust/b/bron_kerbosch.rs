const MAX_VERTICES: usize = 5;

fn population_count(mut value: u64) -> u32 {
    let mut count = 0;
    while value != 0 {
        count += (value & 1) as u32;
        value >>= 1;
    }
    count
}

fn search(vertex_count: usize, adjacency: &[u64; MAX_VERTICES],
          clique: u64, mut possible: u64, mut excluded: u64) -> u64 {
    if possible == 0 && excluded == 0 { return 1_u64 << clique; }

    let mut pivot = None;
    let mut greatest_degree = 0;
    let pivot_choices = possible | excluded;
    for vertex in 0..vertex_count {
        if pivot_choices & (1_u64 << vertex) == 0 { continue; }
        let degree = population_count(adjacency[vertex]);
        if pivot.is_none() || degree > greatest_degree {
            pivot = Some(vertex);
            greatest_degree = degree;
        }
    }

    let mut candidates = possible;
    if let Some(vertex) = pivot { candidates &= !adjacency[vertex]; }
    let mut result = 0;
    for vertex in 0..vertex_count {
        let bit = 1_u64 << vertex;
        if candidates & bit == 0 { continue; }
        result |= search(vertex_count, adjacency, clique | bit,
                         possible & adjacency[vertex], excluded & adjacency[vertex]);
        possible &= !bit;
        excluded |= bit;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn bron_kerbosch(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=7).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_VERTICES as i64).contains(&values[0]) { return -1; }
    let vertex_count = values[0] as usize;
    if length != vertex_count + 1 { return -1; }

    let vertex_mask = (1_u64 << vertex_count) - 1;
    let mut adjacency = [0_u64; MAX_VERTICES];
    for vertex in 0..vertex_count {
        let row = values[vertex + 1];
        if row < 0 || (row as u64) & !vertex_mask != 0 { return -1; }
        adjacency[vertex] = (row as u64) & !(1_u64 << vertex);
    }
    for left in 0..vertex_count {
        for right in left + 1..vertex_count {
            if (adjacency[left] >> right) & 1 != (adjacency[right] >> left) & 1 { return -1; }
        }
    }
    search(vertex_count, &adjacency, 0, vertex_mask, 0) as i64
}
