const MAX_VERTICES: usize = 12;
const MAX_EDGES: usize = 66;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 135;

#[no_mangle]
pub unsafe extern "C" fn dsatur_greedy_coloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (vertex_value, edge_value) = (values[0], values[1]);
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
    {
        return -1;
    }
    let (n, m) = (vertex_value as usize, edge_value as usize);
    if length != 2 + 2 * m {
        return -1;
    }

    let mut adjacency = [0u16; MAX_VERTICES];
    for edge in 0..m {
        let (u_value, v_value) = (values[2 + 2 * edge], values[3 + 2 * edge]);
        if u_value < 0 || v_value <= u_value || v_value >= vertex_value {
            return -1;
        }
        let (u, v) = (u_value as usize, v_value as usize);
        let v_bit = 1u16 << v;
        if adjacency[u] & v_bit != 0 {
            return -1;
        }
        adjacency[u] |= v_bit;
        adjacency[v] |= 1u16 << u;
    }

    let mut colors = [-1i32; MAX_VERTICES];
    let mut saturation_colors = [0u16; MAX_VERTICES];
    let mut residual_degree = [0i32; MAX_VERTICES];
    for vertex in 0..n {
        residual_degree[vertex] = adjacency[vertex].count_ones() as i32;
    }

    let mut color_count = 0i64;
    for _ in 0..n {
        let mut selected = None;
        let mut selected_saturation = 0u32;
        let mut selected_degree = 0i32;
        for vertex in 0..n {
            if colors[vertex] >= 0 {
                continue;
            }
            let saturation = saturation_colors[vertex].count_ones();
            let degree = residual_degree[vertex];
            if selected.is_none()
                || saturation > selected_saturation
                || (saturation == selected_saturation && degree > selected_degree)
            {
                selected = Some(vertex);
                selected_saturation = saturation;
                selected_degree = degree;
            }
        }
        let vertex = match selected {
            Some(value) => value,
            None => return -1,
        };

        let used_colors = saturation_colors[vertex];
        let color = (0..MAX_VERTICES)
            .find(|&candidate| used_colors & (1u16 << candidate) == 0);
        let color = match color {
            Some(value) => value,
            None => return -1,
        };
        colors[vertex] = color as i32;
        color_count = color_count.max(color as i64 + 1);
        let color_bit = 1u16 << color;
        for neighbor in 0..n {
            if colors[neighbor] < 0 && adjacency[vertex] & (1u16 << neighbor) != 0 {
                residual_degree[neighbor] -= 1;
                saturation_colors[neighbor] |= color_bit;
            }
        }
    }

    let mut packed = color_count << 48;
    for vertex in 0..n {
        packed |= (colors[vertex] as i64) << (4 * vertex);
    }
    packed
}
