#[no_mangle]
pub unsafe extern "C" fn lovasz_toggle_defective_coloring_trace(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(5..=246).contains(&length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n_value, red_bound, blue_bound) = (values[0], values[1], values[2]);
    if !(0..=16).contains(&n_value)
        || !(1..=8).contains(&red_bound)
        || !(1..=8).contains(&blue_bound)
    {
        return -1;
    }
    let n = n_value as usize;
    let red_mask_value = values[3];
    if red_mask_value < 0 || red_mask_value as u64 >= (1u64 << n) {
        return -1;
    }
    let m_value = values[4];
    let maximum_edges = n_value * (n_value - 1) / 2;
    if m_value < 0 || m_value > maximum_edges || length != 5 + 2 * m_value as usize {
        return -1;
    }
    let m = m_value as usize;

    let mut adjacency = [0u32; 16];
    let mut degree = [0i64; 16];
    for edge in 0..m {
        let u_value = values[5 + 2 * edge];
        let v_value = values[6 + 2 * edge];
        if u_value < 0 || v_value <= u_value || v_value >= n_value {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        let bit_v = 1u32 << v;
        let bit_u = 1u32 << u;
        if (adjacency[u] & bit_v) != 0 {
            return -1;
        }
        adjacency[u] |= bit_v;
        adjacency[v] |= bit_u;
        degree[u] += 1;
        degree[v] += 1;
    }
    if degree[..n].iter().any(|&d| d > red_bound + blue_bound + 1) {
        return -1;
    }

    let mut red_mask = red_mask_value as u64;
    let mut toggle_count = 0i64;
    loop {
        let mut bad_vertex = None;
        for vertex in 0..n {
            let mut red_degree = 0i64;
            for neighbor in 0..n {
                if (adjacency[vertex] & (1u32 << neighbor)) != 0
                    && (red_mask & (1u64 << neighbor)) != 0
                {
                    red_degree += 1;
                }
            }
            let blue_degree = degree[vertex] - red_degree;
            let is_red = (red_mask & (1u64 << vertex)) != 0;
            if (is_red && red_degree > red_bound) || (!is_red && blue_degree > blue_bound) {
                bad_vertex = Some(vertex);
                break;
            }
        }
        match bad_vertex {
            Some(vertex) => {
                red_mask ^= 1u64 << vertex;
                toggle_count += 1;
            }
            None => break,
        }
    }
    (toggle_count << n) | red_mask as i64
}
