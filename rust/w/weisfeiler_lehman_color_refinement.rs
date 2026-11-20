const MAX_VERTICES: usize = 8;
const MAX_INPUT_LENGTH: usize = 9;
const INVALID_RESULT: i64 = -1;
const DEGREE_COLOR_PLACE: i64 = 43_046_721;

fn bit_count(mut value: i64) -> i64 {
    let mut count = 0;
    while value != 0 {
        count += value & 1;
        value >>= 1;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn weisfeiler_lehman_color_refinement(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 {
        return INVALID_RESULT;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if !(0..=MAX_VERTICES as i64).contains(&values[0]) {
        return INVALID_RESULT;
    }
    let n = values[0] as usize;
    if length != 1 + n {
        return INVALID_RESULT;
    }

    let allowed = (1_i64 << n) - 1;
    let mut adjacency = [0_i64; MAX_VERTICES];
    let mut colors = [0_i64; MAX_VERTICES];
    let mut next_colors = [0_i64; MAX_VERTICES];
    let mut class_count = 0_usize;
    for vertex in 0..n {
        let mask = values[1 + vertex];
        if mask < 0 || mask & !allowed != 0 || mask & (1_i64 << vertex) != 0 {
            return INVALID_RESULT;
        }
        adjacency[vertex] = mask;
        colors[vertex] = bit_count(mask);
        let mut first_degree = true;
        for prior in 0..vertex {
            if colors[prior] == colors[vertex] {
                first_degree = false;
            }
            if ((adjacency[vertex] >> prior) & 1) != ((adjacency[prior] >> vertex) & 1) {
                return INVALID_RESULT;
            }
        }
        if first_degree {
            class_count += 1;
        }
    }
    if n == 0 {
        return 0;
    }

    loop {
        let mut keys = [0_i64; MAX_VERTICES];
        let mut unique_keys = [0_i64; MAX_VERTICES];
        let mut unique_count = 0;
        for vertex in 0..n {
            let mut neighbor_colors = [0_i64; MAX_VERTICES];
            let mut neighbor_count = 0;
            for neighbor in 0..n {
                if adjacency[vertex] & (1_i64 << neighbor) == 0 {
                    continue;
                }
                let value = colors[neighbor];
                let mut position = neighbor_count;
                while position > 0 && neighbor_colors[position - 1] > value {
                    neighbor_colors[position] = neighbor_colors[position - 1];
                    position -= 1;
                }
                neighbor_colors[position] = value;
                neighbor_count += 1;
            }
            let mut suffix = 0_i64;
            for slot in 0..MAX_VERTICES {
                suffix *= 9;
                if slot < neighbor_count {
                    suffix += neighbor_colors[slot] + 1;
                }
            }
            keys[vertex] = colors[vertex] * DEGREE_COLOR_PLACE + suffix;
            if !(0..vertex).any(|prior| keys[prior] == keys[vertex]) {
                unique_keys[unique_count] = keys[vertex];
                unique_count += 1;
            }
        }

        for index in 1..unique_count {
            let value = unique_keys[index];
            let mut position = index;
            while position > 0 && unique_keys[position - 1] > value {
                unique_keys[position] = unique_keys[position - 1];
                position -= 1;
            }
            unique_keys[position] = value;
        }
        for vertex in 0..n {
            let mut rank = 0;
            while unique_keys[rank] != keys[vertex] {
                rank += 1;
            }
            next_colors[vertex] = rank as i64;
        }
        for vertex in 0..n {
            colors[vertex] = next_colors[vertex];
        }
        if unique_count == class_count {
            break;
        }
        class_count = unique_count;
    }

    let mut packed = 0_i64;
    let mut place = 1_i64;
    for color in &colors[..n] {
        packed += color * place;
        place *= 9;
    }
    packed
}
