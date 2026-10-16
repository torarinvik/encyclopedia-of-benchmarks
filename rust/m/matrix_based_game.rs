const MAX_INPUT_LENGTH: usize = 194;
const MAX_MOVES: i64 = 64;

fn matrix_based_game_is_symbol(value: i64) -> bool {
    (48..=57).contains(&value) || (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn matrix_based_game(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let n_value = input[0];
    if !(1..=8).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let cells = n * n;
    let move_count_index = 1 + cells;
    if length < move_count_index + 1 { return -1; }
    let move_count_value = input[move_count_index];
    if !(0..=MAX_MOVES).contains(&move_count_value) { return -1; }
    let move_count = move_count_value as usize;
    if length != 2 + cells + 2 * move_count { return -1; }

    let mut board = [0i64; 64];
    let mut visited = [false; 64];
    let mut stack = [0usize; 64];
    for index in 0..cells {
        if !matrix_based_game_is_symbol(input[1 + index]) { return -1; }
        board[index] = input[1 + index];
    }
    for movement in 0..move_count {
        let x = input[move_count_index + 1 + 2 * movement];
        let y = input[move_count_index + 2 + 2 * movement];
        if x < 0 || x >= n_value || y < 0 || y >= n_value { return -1; }
    }

    let mut total_score = 0i64;
    for movement in 0..move_count {
        let x = input[move_count_index + 1 + 2 * movement] as usize;
        let y = input[move_count_index + 2 + 2 * movement] as usize;
        let start_row = n - 1 - y;
        let start = start_row * n + x;
        let color = board[start];
        if color == -1 { continue; }

        for index in 0..cells { visited[index] = false; }
        let mut stack_count = 0usize;
        stack[stack_count] = start;
        stack_count += 1;
        visited[start] = true;
        let mut component_size = 0i64;
        while stack_count > 0 {
            stack_count -= 1;
            let current = stack[stack_count];
            let row = current / n;
            let col = current % n;
            if row > 0 {
                let neighbor = current - n;
                if !visited[neighbor] && board[neighbor] == color {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            if row + 1 < n {
                let neighbor = current + n;
                if !visited[neighbor] && board[neighbor] == color {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            if col > 0 {
                let neighbor = current - 1;
                if !visited[neighbor] && board[neighbor] == color {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            if col + 1 < n {
                let neighbor = current + 1;
                if !visited[neighbor] && board[neighbor] == color {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            board[current] = -1;
            component_size += 1;
        }
        total_score += component_size * (component_size + 1) / 2;

        for col in 0..n {
            let mut target_row = n;
            for row in (0..n).rev() {
                let value = board[row * n + col];
                if value != -1 {
                    target_row -= 1;
                    board[target_row * n + col] = value;
                }
            }
            for row in 0..target_row { board[row * n + col] = -1; }
        }
        let mut write_col = 0usize;
        for col in 0..n {
            let mut nonempty = false;
            for row in 0..n {
                if board[row * n + col] != -1 { nonempty = true; }
            }
            if !nonempty { continue; }
            if write_col != col {
                for row in 0..n { board[row * n + write_col] = board[row * n + col]; }
            }
            write_col += 1;
        }
        for col in write_col..n {
            for row in 0..n { board[row * n + col] = -1; }
        }
    }
    total_score
}
