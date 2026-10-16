#include <stddef.h>
#include <stdint.h>

static int matrix_based_game_is_symbol(int64_t value) {
    return (value >= 48 && value <= 57) ||
           (value >= 65 && value <= 90) ||
           (value >= 97 && value <= 122);
}

int64_t matrix_based_game(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > 194) return -1;
    const int64_t n_value = values[0];
    if (n_value < 1 || n_value > 8) return -1;
    const size_t n = (size_t)n_value;
    const size_t cells = n * n;
    const size_t move_count_index = 1 + cells;
    if (length < move_count_index + 1) return -1;
    const int64_t move_count_value = values[move_count_index];
    if (move_count_value < 0 || move_count_value > 64) return -1;
    const size_t move_count = (size_t)move_count_value;
    if (length != 2 + cells + 2 * move_count) return -1;

    int64_t board[64];
    int visited[64];
    size_t stack[64];
    for (size_t index = 0; index < cells; ++index) {
        if (!matrix_based_game_is_symbol(values[1 + index])) return -1;
        board[index] = values[1 + index];
    }
    for (size_t move = 0; move < move_count; ++move) {
        const int64_t x = values[move_count_index + 1 + 2 * move];
        const int64_t y = values[move_count_index + 2 + 2 * move];
        if (x < 0 || x >= n_value || y < 0 || y >= n_value) return -1;
    }

    int64_t total_score = 0;
    for (size_t move = 0; move < move_count; ++move) {
        const size_t x = (size_t)values[move_count_index + 1 + 2 * move];
        const size_t y = (size_t)values[move_count_index + 2 + 2 * move];
        const size_t start_row = n - 1 - y;
        const size_t start = start_row * n + x;
        const int64_t color = board[start];
        if (color == -1) continue;

        for (size_t index = 0; index < cells; ++index) visited[index] = 0;
        size_t stack_count = 0;
        stack[stack_count++] = start;
        visited[start] = 1;
        int64_t component_size = 0;
        while (stack_count > 0) {
            const size_t current = stack[--stack_count];
            const size_t row = current / n;
            const size_t col = current % n;
            if (row > 0) {
                const size_t neighbor = current - n;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = 1;
                    stack[stack_count++] = neighbor;
                }
            }
            if (row + 1 < n) {
                const size_t neighbor = current + n;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = 1;
                    stack[stack_count++] = neighbor;
                }
            }
            if (col > 0) {
                const size_t neighbor = current - 1;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = 1;
                    stack[stack_count++] = neighbor;
                }
            }
            if (col + 1 < n) {
                const size_t neighbor = current + 1;
                if (!visited[neighbor] && board[neighbor] == color) {
                    visited[neighbor] = 1;
                    stack[stack_count++] = neighbor;
                }
            }
            board[current] = -1;
            ++component_size;
        }
        total_score += component_size * (component_size + 1) / 2;

        for (size_t col = 0; col < n; ++col) {
            size_t target_row = n;
            for (size_t row_cursor = n; row_cursor > 0; --row_cursor) {
                const size_t row = row_cursor - 1;
                const int64_t value = board[row * n + col];
                if (value != -1) board[--target_row * n + col] = value;
            }
            for (size_t row = 0; row < target_row; ++row) board[row * n + col] = -1;
        }
        size_t write_col = 0;
        for (size_t col = 0; col < n; ++col) {
            int nonempty = 0;
            for (size_t row = 0; row < n; ++row) {
                if (board[row * n + col] != -1) nonempty = 1;
            }
            if (!nonempty) continue;
            if (write_col != col) {
                for (size_t row = 0; row < n; ++row) board[row * n + write_col] = board[row * n + col];
            }
            ++write_col;
        }
        for (size_t col = write_col; col < n; ++col) {
            for (size_t row = 0; row < n; ++row) board[row * n + col] = -1;
        }
    }
    return total_score;
}
