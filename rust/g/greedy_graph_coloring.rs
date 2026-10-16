const MAX_VERTICES: usize = 14;

#[no_mangle]
pub unsafe extern "C" fn greedy_graph_coloring(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_VERTICES + 1).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let count_value = values[0];
    if !(0..=MAX_VERTICES as i64).contains(&count_value) || length != count_value as usize + 1 { return -1; }
    let count = count_value as usize;
    let limit = (1i64 << count) - 1;
    let mut adjacency = [0i64; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    let mut order = [0usize; MAX_VERTICES];
    let mut colors = [0usize; MAX_VERTICES];
    for vertex in 0..count {
        let mask = values[1 + vertex];
        if mask < 0 || mask > limit || mask & (1i64 << vertex) != 0 { return -1; }
        adjacency[vertex] = mask;
        order[vertex] = vertex;
        let mut remaining = mask;
        while remaining != 0 { remaining &= remaining - 1; degree[vertex] += 1; }
    }
    for vertex in 0..count {
        for other in 0..count {
            if ((adjacency[vertex] >> other) & 1) != ((adjacency[other] >> vertex) & 1) { return -1; }
        }
    }
    for index in 1..count {
        let current = order[index];
        let mut position = index;
        while position > 0 && degree[order[position - 1]] < degree[current] {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    let mut color_count = 0usize;
    for &vertex in &order[..count] {
        let mut used = 0u64;
        for other in 0..count {
            if adjacency[vertex] & (1i64 << other) != 0 && colors[other] != 0 { used |= 1u64 << colors[other]; }
        }
        let mut color = 1usize;
        while used & (1u64 << color) != 0 { color += 1; }
        colors[vertex] = color;
        color_count = color_count.max(color);
    }
    let mut packed = color_count as i64;
    for vertex in 0..count { packed |= (colors[vertex] as i64) << (4 * (vertex + 1)); }
    packed
}
