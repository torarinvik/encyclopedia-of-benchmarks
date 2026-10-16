const MAX_INPUT_LENGTH: usize = 194;
const MAX_MOVES: i64 = 64;

fn matrixBasedGameIsSymbol(value: i64) bool {
    return (value >= 48 and value <= 57) or
        (value >= 65 and value <= 90) or
        (value >= 97 and value <= 122);
}

export fn matrix_based_game(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = values.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > 8) return -1;
    const n: usize = @intCast(n_value);
    const cells = n * n;
    const move_count_index = 1 + cells;
    if (length < move_count_index + 1) return -1;
    const move_count_value = input[move_count_index];
    if (move_count_value < 0 or move_count_value > MAX_MOVES) return -1;
    const move_count: usize = @intCast(move_count_value);
    if (length != 2 + cells + 2 * move_count) return -1;

    var board: [64]i64 = @splat(0);
    var visited: [64]bool = @splat(false);
    var stack: [64]usize = @splat(0);
    for (0..cells) |index| {
        if (!matrixBasedGameIsSymbol(input[1 + index])) return -1;
        board[index] = input[1 + index];
    }
    for (0..move_count) |movement| {
        const x = input[move_count_index + 1 + 2 * movement];
        const y = input[move_count_index + 2 + 2 * movement];
        if (x < 0 or x >= n_value or y < 0 or y >= n_value) return -1;
    }

    var total_score: i64 = 0;
    for (0..move_count) |movement| {
        const x: usize = @intCast(input[move_count_index + 1 + 2 * movement]);
        const y: usize = @intCast(input[move_count_index + 2 + 2 * movement]);
        const start_row = n - 1 - y;
        const start = start_row * n + x;
        const color = board[start];
        if (color == -1) continue;

        for (0..cells) |index| visited[index] = false;
        var stack_count: usize = 0;
        stack[stack_count] = start;
        stack_count += 1;
        visited[start] = true;
        var component_size: i64 = 0;
        while (stack_count > 0) {
            stack_count -= 1;
            const current = stack[stack_count];
            const row = current / n;
            const col = current % n;
            if (row > 0) {
                const neighbor = current - n;
                if (!visited[neighbor] and board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            if (row + 1 < n) {
                const neighbor = current + n;
                if (!visited[neighbor] and board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            if (col > 0) {
                const neighbor = current - 1;
                if (!visited[neighbor] and board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            if (col + 1 < n) {
                const neighbor = current + 1;
                if (!visited[neighbor] and board[neighbor] == color) {
                    visited[neighbor] = true;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
            }
            board[current] = -1;
            component_size += 1;
        }
        total_score += component_size * (component_size + 1) / 2;

        for (0..n) |col| {
            var target_row = n;
            var row_cursor = n;
            while (row_cursor > 0) {
                row_cursor -= 1;
                const value = board[row_cursor * n + col];
                if (value != -1) {
                    target_row -= 1;
                    board[target_row * n + col] = value;
                }
            }
            for (0..target_row) |row| board[row * n + col] = -1;
        }
        var write_col: usize = 0;
        for (0..n) |col| {
            var nonempty = false;
            for (0..n) |row| {
                if (board[row * n + col] != -1) nonempty = true;
            }
            if (!nonempty) continue;
            if (write_col != col) {
                for (0..n) |row| board[row * n + write_col] = board[row * n + col];
            }
            write_col += 1;
        }
        for (write_col..n) |col| {
            for (0..n) |row| board[row * n + col] = -1;
        }
    }
    return total_score;
}
