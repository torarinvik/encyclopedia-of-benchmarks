module matrix_based_game;

fn bool matrix_based_game_is_symbol(long value) {
    return (value >= 48 && value <= 57) ||
           (value >= 65 && value <= 90) ||
           (value >= 97 && value <= 122);
}

fn long matrix_based_game(long* values, usz length) @export("matrix_based_game") {
    if (values == null || length < 2 || length > 194) return -1;
    long n_value = values[0];
    if (n_value < 1 || n_value > 8) return -1;
    usz n = (usz)n_value;
    usz cells = n * n;
    usz move_count_index = 1 + cells;
    if (length < move_count_index + 1) return -1;
    long move_count_value = values[move_count_index];
    if (move_count_value < 0 || move_count_value > 64) return -1;
    usz move_count = (usz)move_count_value;
    if (length != 2 + cells + 2 * move_count) return -1;

    long[64] board;
    bool[64] visited;
    usz[64] stack;
    for (usz index = 0; index < cells; index++) {
        if (!matrix_based_game_is_symbol(values[1 + index])) return -1;
        board[index] = values[1 + index];
    }
    for (usz move = 0; move < move_count; move++) {
        long x = values[move_count_index + 1 + 2 * move];
        long y = values[move_count_index + 2 + 2 * move];
        if (x < 0 || x >= n_value || y < 0 || y >= n_value) return -1;
    }

    long total_score = 0;
    for (usz move = 0; move < move_count; move++) {
        usz x = (usz)values[move_count_index + 1 + 2 * move];
        usz y = (usz)values[move_count_index + 2 + 2 * move];
        usz start_row = n - 1 - y;
        usz start = start_row * n + x;
        long color = board[start];
        if (color == -1) continue;

        for (usz index = 0; index < cells; index++) visited[index] = false;
        usz stack_count = 0;
        stack[stack_count++] = start;
        visited[start] = true;
        long component_size = 0;
        while (stack_count > 0) {
            usz current = stack[--stack_count];
            usz row = current / n;
            usz col = current % n;
            if (row > 0) {
                usz neighbor = current - n;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count++] = neighbor;
                }
            }
            if (row + 1 < n) {
                usz neighbor = current + n;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count++] = neighbor;
                }
            }
            if (col > 0) {
                usz neighbor = current - 1;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count++] = neighbor;
                }
            }
            if (col + 1 < n) {
                usz neighbor = current + 1;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count++] = neighbor;
                }
            }
            board[current] = -1;
            component_size++;
        }
        total_score += component_size * (component_size + 1) / 2;

        for (usz col = 0; col < n; col++) {
            usz target_row = n;
            for (usz row_cursor = n; row_cursor > 0; row_cursor--) {
                usz row = row_cursor - 1;
                long value = board[row * n + col];
                if (value != -1) {
                    target_row--;
                    board[target_row * n + col] = value;
                }
            }
            for (usz row = 0; row < target_row; row++) board[row * n + col] = -1;
        }
        usz write_col = 0;
        for (usz col = 0; col < n; col++) {
            bool nonempty = false;
            for (usz row = 0; row < n; row++) {
                if (board[row * n + col] != -1) nonempty = true;
            }
            if (!nonempty) continue;
            if (write_col != col) {
                for (usz row = 0; row < n; row++) board[row * n + write_col] = board[row * n + col];
            }
            write_col++;
        }
        for (usz col = write_col; col < n; col++) {
            for (usz row = 0; row < n; row++) board[row * n + col] = -1;
        }
    }
    return total_score;
}
