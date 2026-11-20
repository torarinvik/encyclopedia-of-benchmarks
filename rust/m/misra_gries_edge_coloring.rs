fn free_color(vertex: usize, color: i64, vertices: usize,
             edge_at: &[[i32; 6]; 6], colors: &[i64; 6]) -> bool {
    (0..vertices).all(|other| {
        let edge = edge_at[vertex][other];
        edge < 0 || colors[edge as usize] != color
    })
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > 15 || !(1..=6).contains(&input[0])
        || !(0..=6).contains(&input[1]) { return -1; }
    let vertices = input[0] as usize;
    let edge_count = input[1] as usize;
    if input.len() != 2 + 2 * edge_count { return -1; }
    let mut left = [0usize; 6];
    let mut right = [0usize; 6];
    let mut degree = [0usize; 6];
    let mut edge_at = [[-1i32; 6]; 6];
    for edge in 0..edge_count {
        let a = input[2 + 2 * edge];
        let b = input[3 + 2 * edge];
        if a < 0 || b < 0 || a >= vertices as i64 || b >= vertices as i64 || a == b { return -1; }
        let u = a.min(b) as usize;
        let v = a.max(b) as usize;
        if edge_at[u][v] >= 0 { return -1; }
        left[edge] = u; right[edge] = v;
        edge_at[u][v] = edge as i32;
        edge_at[v][u] = edge as i32;
        degree[u] += 1; degree[v] += 1;
    }
    let delta = *degree[..vertices].iter().max().unwrap_or(&0);
    let palette = if edge_count == 0 { 0 } else { delta + 1 };
    let mut colors = [-1i64; 6];

    for edge in 0..edge_count {
        let center = left[edge];
        let mut fan = [0usize; 6];
        let mut fan_count = 1usize;
        fan[0] = right[edge];
        loop {
            let tail = fan[fan_count - 1];
            let mut extended = false;
            for neighbor in 0..vertices {
                let candidate = edge_at[center][neighbor];
                if candidate < 0 || colors[candidate as usize] < 0 { continue; }
                if fan[..fan_count].contains(&neighbor)
                    || !free_color(tail, colors[candidate as usize], vertices, &edge_at, &colors) { continue; }
                fan[fan_count] = neighbor;
                fan_count += 1;
                extended = true;
                break;
            }
            if !extended { break; }
        }
        let mut color_c = 0i64;
        while color_c < palette as i64 && !free_color(center, color_c, vertices, &edge_at, &colors) { color_c += 1; }
        let mut color_d = 0i64;
        while color_d < palette as i64 && !free_color(fan[fan_count - 1], color_d, vertices, &edge_at, &colors) { color_d += 1; }
        if color_c >= palette as i64 || color_d >= palette as i64 { return -1; }

        let mut path = [0usize; 6];
        let mut path_count = 0usize;
        let mut current = center;
        let mut wanted = color_d;
        let mut visited = [false; 6];
        visited[current] = true;
        for _ in 0..vertices {
            let mut path_edge = -1i32;
            let mut next = 0usize;
            for neighbor in 0..vertices {
                let candidate = edge_at[current][neighbor];
                if candidate >= 0 && colors[candidate as usize] == wanted {
                    path_edge = candidate; next = neighbor; break;
                }
            }
            if path_edge < 0 || visited[next] { break; }
            path[path_count] = path_edge as usize;
            path_count += 1;
            visited[next] = true;
            current = next;
            wanted = if wanted == color_d { color_c } else { color_d };
        }
        for path_edge in path[..path_count].iter().copied() {
            colors[path_edge] = if colors[path_edge] == color_d { color_c } else { color_d };
        }

        let mut prefix_end = fan_count;
        for i in 0..fan_count {
            if free_color(fan[i], color_d, vertices, &edge_at, &colors) { prefix_end = i; break; }
        }
        if prefix_end == fan_count { return -1; }
        let mut shifted = [0i64; 6];
        for i in 0..prefix_end { shifted[i] = colors[edge_at[center][fan[i + 1]] as usize]; }
        for i in 0..prefix_end { colors[edge_at[center][fan[i]] as usize] = shifted[i]; }
        colors[edge_at[center][fan[prefix_end]] as usize] = color_d;
    }

    let mut signature = 0i64;
    for edge in 0..edge_count { signature |= colors[edge] << (3 * edge); }
    palette as i64 * 262144 + signature
}

#[no_mangle]
pub unsafe extern "C" fn misra_gries_edge_coloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 15 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
