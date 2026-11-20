const CODE_STATES: usize = 6561;
const MAX_STATES: usize = 78_732;

fn cell_color(code: i64) -> i64 {
    if code == 0 { -1 } else if code <= 4 { 0 } else { 1 }
}

fn advance_frontier(input_codes: &[i64; 4], closed: i64, diagonal: i64,
                    color: i64, row: usize, column: usize,
                    output_codes: &mut [i64; 4], output_closed: &mut i64,
                    output_diagonal: &mut i64) -> bool {
    if closed & (1 << color) != 0 { return false; }
    let above = input_codes[column];
    let left = if column == 0 { 0 } else { input_codes[column - 1] };
    if row != 0 && column != 0 && cell_color(above) == color &&
        cell_color(left) == color && diagonal == color + 1 { return false; }

    *output_codes = *input_codes;
    output_codes[column] = 0;
    let above_color = cell_color(above);
    let above_label = if above_color == color { if color == 0 { above } else { above - 4 } } else { 0 };
    let left_label = if cell_color(left) == color { if color == 0 { left } else { left - 4 } } else { 0 };
    let mut chosen_label = if above_label != 0 { above_label } else { left_label };
    if above_label != 0 && left_label != 0 && above_label != left_label {
        for code in output_codes.iter_mut() {
            if color == 0 && *code == left_label { *code = above_label; }
            if color == 1 && *code == 4 + left_label { *code = 4 + above_label; }
        }
        chosen_label = above_label;
    }
    if chosen_label == 0 {
        let mut maximum = 0;
        for &code in output_codes.iter() {
            if cell_color(code) == color {
                let label = if color == 0 { code } else { code - 4 };
                maximum = maximum.max(label);
            }
        }
        chosen_label = maximum + 1;
    }
    output_codes[column] = if color == 0 { chosen_label } else { 4 + chosen_label };

    *output_closed = closed;
    if above != 0 && above_color != color {
        let mut old_still_present = false;
        let mut other_same_color = false;
        for &code in output_codes.iter() {
            if code == above { old_still_present = true; }
            if cell_color(code) == above_color && code != above { other_same_color = true; }
        }
        if !old_still_present {
            if other_same_color { return false; }
            *output_closed |= 1 << above_color;
        }
    }

    let mut mapping = [0i64; 9];
    let mut next_black = 0;
    let mut next_white = 0;
    for code in output_codes.iter_mut() {
        if *code == 0 { continue; }
        if *code <= 4 {
            let key = *code as usize;
            if mapping[key] == 0 { next_black += 1; mapping[key] = next_black; }
            *code = mapping[key];
        } else {
            let key = *code as usize;
            if mapping[key] == 0 { next_white += 1; mapping[key] = 4 + next_white; }
            *code = mapping[key];
        }
    }
    *output_diagonal = if above_color < 0 { 0 } else { above_color + 1 };
    true
}

fn encode_state(codes: &[i64; 4], closed: i64, diagonal: i64) -> usize {
    const POWERS: [usize; 4] = [1, 9, 81, 729];
    let mut code_key = 0usize;
    for slot in 0..4 { code_key += codes[slot] as usize * POWERS[slot]; }
    ((closed as usize * 3 + diagonal as usize) * CODE_STATES) + code_key
}

#[no_mangle]
pub unsafe extern "C" fn connectivity_aware_plug_dp_binary_grid_colorings(
    input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let rows_value = *input;
    let columns_value = *input.add(1);
    if !(2..=4).contains(&rows_value) || !(2..=4).contains(&columns_value) { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;

    let mut dp = [0i64; MAX_STATES];
    let mut next = [0i64; MAX_STATES];
    dp[0] = 1;
    for cell in 0..rows * columns {
        let row = cell / columns;
        let column = cell % columns;
        next.fill(0);
        for state in 0..MAX_STATES {
            if dp[state] == 0 { continue; }
            let mut code_key = state % CODE_STATES;
            let flags = state / CODE_STATES;
            let diagonal = (flags % 3) as i64;
            let closed = (flags / 3) as i64;
            let mut codes = [0i64; 4];
            for code in &mut codes { *code = (code_key % 9) as i64; code_key /= 9; }
            for color in 0..=1i64 {
                let mut output_codes = [0i64; 4];
                let mut output_closed = 0;
                let mut output_diagonal = 0;
                if advance_frontier(&codes, closed, diagonal, color, row, column,
                                    &mut output_codes, &mut output_closed, &mut output_diagonal) {
                    let destination = encode_state(&output_codes, output_closed, output_diagonal);
                    next[destination] += dp[state];
                }
            }
        }
        dp.copy_from_slice(&next);
    }

    let mut total = 0i64;
    for state in 0..MAX_STATES {
        if dp[state] == 0 { continue; }
        let mut code_key = state % CODE_STATES;
        let closed = ((state / CODE_STATES) / 3) as i64;
        let mut seen_black = [false; 5];
        let mut seen_white = [false; 5];
        let mut black_components = 0;
        let mut white_components = 0;
        for _ in 0..4 {
            let code = code_key % 9;
            code_key /= 9;
            if (1..=4).contains(&code) && !seen_black[code] {
                seen_black[code] = true;
                black_components += 1;
            } else if (5..=8).contains(&code) && !seen_white[code - 4] {
                seen_white[code - 4] = true;
                white_components += 1;
            }
        }
        if ((closed & 1 != 0 && black_components == 0) || (closed & 1 == 0 && black_components == 1)) &&
           ((closed & 2 != 0 && white_components == 0) || (closed & 2 == 0 && white_components == 1)) {
            total += dp[state];
        }
    }
    total
}
