/// Myers furthest-reaching edit-graph search for a bounded byte script.
const MAX_SEQUENCE: usize = 16;
const MAX_DISTANCE: usize = 32;
const MAX_OUTPUT: usize = 48;
const OFFSET: isize = 33;
const DIAGONALS: usize = 67;

fn build_script(first: &[i64], second: &[i64]) -> ([u8; MAX_OUTPUT], usize) {
    let n = first.len();
    let m = second.len();
    let mut frontier = [-1i32; DIAGONALS];
    let mut trace = [[-1i32; DIAGONALS]; MAX_DISTANCE + 1];
    frontier[(OFFSET + 1) as usize] = 0;

    let mut found_distance = 0usize;
    let mut found_diagonal = 0isize;
    'search: for distance in 0..=n + m {
        let d = distance as isize;
        let mut diagonal = -d;
        while diagonal <= d {
            let slot = (OFFSET + diagonal) as usize;
            let mut x: isize;
            if diagonal == -d
                || (diagonal != d && frontier[slot - 1] < frontier[slot + 1])
            {
                x = frontier[slot + 1] as isize;
            } else {
                x = frontier[slot - 1] as isize + 1;
            }
            let mut y = x - diagonal;
            while x < n as isize && y < m as isize
                && first[x as usize] == second[y as usize]
            {
                x += 1;
                y += 1;
            }
            frontier[slot] = x as i32;
            trace[distance][slot] = x as i32;
            if x >= n as isize && y >= m as isize {
                found_distance = distance;
                found_diagonal = diagonal;
                break 'search;
            }
            diagonal += 2;
        }
    }

    let mut reverse_ops = [0u8; MAX_DISTANCE];
    let mut reverse_symbols = [0u8; MAX_DISTANCE];
    let mut path_length = 0usize;
    let mut x = n as isize;
    let mut y = m as isize;
    let mut diagonal = found_diagonal;
    for distance in (1..=found_distance).rev() {
        let d = distance as isize;
        let slot = (OFFSET + diagonal) as usize;
        let previous_row = &trace[distance - 1];
        let previous_diagonal: isize;
        let previous_x: isize;
        let previous_y: isize;
        let snake_x: isize;
        let snake_y: isize;
        if diagonal == -d
            || (diagonal != d && previous_row[slot - 1] < previous_row[slot + 1])
        {
            previous_diagonal = diagonal + 1;
            previous_x = previous_row[(OFFSET + previous_diagonal) as usize] as isize;
            previous_y = previous_x - previous_diagonal;
            snake_x = previous_x;
            snake_y = previous_y + 1;
            while x > snake_x && y > snake_y {
                reverse_ops[path_length] = 0;
                reverse_symbols[path_length] = 0;
                path_length += 1;
                x -= 1;
                y -= 1;
            }
            reverse_ops[path_length] = 2;
            reverse_symbols[path_length] = second[previous_y as usize] as u8;
            path_length += 1;
        } else {
            previous_diagonal = diagonal - 1;
            previous_x = previous_row[(OFFSET + previous_diagonal) as usize] as isize;
            previous_y = previous_x - previous_diagonal;
            snake_x = previous_x + 1;
            snake_y = previous_y;
            while x > snake_x && y > snake_y {
                reverse_ops[path_length] = 0;
                reverse_symbols[path_length] = 0;
                path_length += 1;
                x -= 1;
                y -= 1;
            }
            reverse_ops[path_length] = 1;
            reverse_symbols[path_length] = 0;
            path_length += 1;
        }
        x = previous_x;
        y = previous_y;
        diagonal = previous_diagonal;
    }

    for _ in 0..trace[0][OFFSET as usize] as usize {
        reverse_ops[path_length] = 0;
        reverse_symbols[path_length] = 0;
        path_length += 1;
    }
    let mut result = [0u8; MAX_OUTPUT];
    let mut written = 0usize;
    for step_index in 0..path_length {
        let step = path_length - step_index - 1;
        let operation = reverse_ops[step];
        result[written] = operation;
        written += 1;
        if operation == 2 {
            result[written] = reverse_symbols[step];
            written += 1;
        }
    }
    (result, written)
}

#[no_mangle]
pub unsafe extern "C" fn myers_ond_shortest_edit_script(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=2 + 2 * MAX_SEQUENCE).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    if !(0..=MAX_SEQUENCE as i64).contains(&n_value)
        || !(0..=MAX_SEQUENCE as i64).contains(&m_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + n + m || values[2..].iter().any(|&value| !(0..=255).contains(&value)) {
        return -1;
    }

    let (script, needed) = build_script(&values[2..2 + n], &values[2 + n..]);
    if output.is_null() || output_capacity < needed {
        return -2;
    }
    std::ptr::copy_nonoverlapping(script.as_ptr(), output, needed);
    needed as i64
}
