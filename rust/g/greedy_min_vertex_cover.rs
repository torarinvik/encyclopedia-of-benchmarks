const MAX_VERTICES: usize = 16;

fn bit_count(mut value: u64) -> i32 {
    let mut count = 0;
    while value != 0 { value &= value - 1; count += 1; }
    count
}

#[no_mangle]
pub unsafe extern "C" fn greedy_min_vertex_cover(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_VERTICES + 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let count_value = input[0];
    if count_value < 1 || count_value > MAX_VERTICES as i64 || length != count_value as usize + 1 { return -1; }
    let count = count_value as usize;
    let limit = (1u64 << count) - 1;
    let mut neighbors = [0u64; MAX_VERTICES];
    for vertex in 0..count {
        let mask_value = input[vertex + 1];
        if mask_value < 0 || mask_value as u64 > limit { return -1; }
        let mask = mask_value as u64;
        if mask & (1u64 << vertex) != 0 { return -1; }
        neighbors[vertex] = mask;
    }
    for vertex in 0..count {
        for other in vertex + 1..count {
            if ((neighbors[vertex] >> other) & 1) != ((neighbors[other] >> vertex) & 1) { return -1; }
        }
    }
    let mut chosen = 0u64;
    loop {
        let (mut best_vertex, mut best_degree) = (None, 0);
        for vertex in 0..count {
            let degree = bit_count(neighbors[vertex]);
            if degree > best_degree { best_vertex = Some(vertex); best_degree = degree; }
        }
        let Some(vertex) = best_vertex else { return chosen as i64; };
        let bit = 1u64 << vertex;
        chosen |= bit;
        for mask in &mut neighbors[..count] { *mask &= !bit; }
        neighbors[vertex] = 0;
    }
}
