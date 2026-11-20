const MAX_SIDE: usize = 8;
const MAX_VERTICES: usize = 2 * MAX_SIDE;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_SIDE + 3;

fn augment_left(
    left: usize,
    left_count: usize,
    right_count: usize,
    rows: &[u16; MAX_SIDE],
    states: &[i8; MAX_VERTICES],
    match_right: &mut [i8; MAX_SIDE],
    seen: &mut [bool; MAX_SIDE],
) -> bool {
    for right in 0..right_count {
        if rows[left] & (1u16 << right) == 0 || seen[right] || states[left_count + right] != -1 {
            continue;
        }
        seen[right] = true;
        let owner = match_right[right];
        if owner == -1 || augment_left(
            owner as usize, left_count, right_count, rows, states, match_right, seen,
        ) {
            match_right[right] = left as i8;
            return true;
        }
    }
    false
}

fn maximum_matching(
    left_count: usize,
    right_count: usize,
    rows: &[u16; MAX_SIDE],
    states: &[i8; MAX_VERTICES],
) -> ([i8; MAX_SIDE], usize) {
    let mut match_right = [-1i8; MAX_SIDE];
    let mut size = 0;
    for left in 0..left_count {
        if states[left] != -1 { continue; }
        let mut seen = [false; MAX_SIDE];
        if augment_left(left, left_count, right_count, rows, states, &mut match_right, &mut seen) {
            size += 1;
        }
    }
    (match_right, size)
}

fn alternating_cover(
    left_count: usize,
    right_count: usize,
    rows: &[u16; MAX_SIDE],
    match_right: &[i8; MAX_SIDE],
) -> u32 {
    let mut matched_left = [false; MAX_SIDE];
    let mut reached_left = [false; MAX_SIDE];
    let mut reached_right = [false; MAX_SIDE];
    let mut queue = [0usize; MAX_SIDE];
    let (mut head, mut tail) = (0usize, 0usize);
    for right in 0..right_count {
        if match_right[right] >= 0 { matched_left[match_right[right] as usize] = true; }
    }
    for left in 0..left_count {
        if !matched_left[left] {
            reached_left[left] = true;
            queue[tail] = left;
            tail += 1;
        }
    }
    while head < tail {
        let left = queue[head];
        head += 1;
        for right in 0..right_count {
            if rows[left] & (1u16 << right) == 0 || reached_right[right] || match_right[right] < 0 {
                continue;
            }
            reached_right[right] = true;
            let owner = match_right[right] as usize;
            if !reached_left[owner] {
                reached_left[owner] = true;
                queue[tail] = owner;
                tail += 1;
            }
        }
    }
    let mut result = 0u32;
    for left in 0..left_count {
        if !reached_left[left] { result |= 1u32 << left; }
    }
    for right in 0..right_count {
        if reached_right[right] { result |= 1u32 << (left_count + right); }
    }
    result
}

fn minimum_completion_size(
    left_count: usize,
    right_count: usize,
    rows: &[u16; MAX_SIDE],
    input_states: &[i8; MAX_VERTICES],
) -> Option<usize> {
    let mut states = *input_states;
    let mut changed = true;
    while changed {
        changed = false;
        for left in 0..left_count {
            for right in 0..right_count {
                if rows[left] & (1u16 << right) == 0 { continue; }
                let right_vertex = left_count + right;
                if states[left] == 0 && states[right_vertex] == 0 { return None; }
                if states[left] == 0 && states[right_vertex] == -1 {
                    states[right_vertex] = 1;
                    changed = true;
                } else if states[right_vertex] == 0 && states[left] == -1 {
                    states[left] = 1;
                    changed = true;
                }
            }
        }
    }
    let forced_in = states[..left_count + right_count].iter().filter(|&&state| state == 1).count();
    let (_, matching_size) = maximum_matching(left_count, right_count, rows, &states);
    Some(forced_in + matching_size)
}

fn canonical_cover(
    left_count: usize,
    right_count: usize,
    rows: &[u16; MAX_SIDE],
    optimum: usize,
) -> u32 {
    let mut states = [-1i8; MAX_VERTICES];
    for vertex in 0..left_count + right_count {
        states[vertex] = 0;
        if minimum_completion_size(left_count, right_count, rows, &states) != Some(optimum) {
            states[vertex] = 1;
        }
    }
    let mut result = 0u32;
    for vertex in 0..left_count + right_count {
        if states[vertex] == 1 { result |= 1u32 << vertex; }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn bipartite_minimum_vertex_cover(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let left_value = values[0];
    let right_value = values[1];
    if left_value < 0 || left_value > MAX_SIDE as i64 || right_value < 0 || right_value > MAX_SIDE as i64 {
        return -1;
    }
    let left_count = left_value as usize;
    let right_count = right_value as usize;
    if length != left_count + 2 { return -1; }
    let right_domain = (1i64 << right_count) - 1;
    let mut rows = [0u16; MAX_SIDE];
    for left in 0..left_count {
        let row = values[2 + left];
        if row < 0 || row & !right_domain != 0 { return -1; }
        rows[left] = row as u16;
    }
    let free_states = [-1i8; MAX_VERTICES];
    let (match_right, matching_size) = maximum_matching(left_count, right_count, &rows, &free_states);
    let optimum = alternating_cover(left_count, right_count, &rows, &match_right).count_ones() as usize;
    if optimum != matching_size { return -1; }
    canonical_cover(left_count, right_count, &rows, optimum) as i64
}
