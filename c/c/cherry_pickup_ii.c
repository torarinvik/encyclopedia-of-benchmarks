#include <stddef.h>
#include <stdint.h>

enum { MAX_DIM = 6, MAX_INPUT = 39 };

int64_t cherry_pickup_ii(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    const int64_t rows_value = input[0], columns_value = input[1];
    if (rows_value < 2 || rows_value > MAX_DIM || columns_value < 2 || columns_value > MAX_DIM) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    if (length != 2 + rows * columns) return -1;
    for (size_t i = 0; i < rows * columns; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 100) return -1;

    int64_t previous[MAX_DIM * MAX_DIM], current[MAX_DIM * MAX_DIM];
    for (size_t i = 0; i < MAX_DIM * MAX_DIM; ++i) previous[i] = -1;
    previous[columns - 1] = input[2] + input[2 + columns - 1];
    for (size_t row = 1; row < rows; ++row) {
        for (size_t i = 0; i < MAX_DIM * MAX_DIM; ++i) current[i] = -1;
        for (size_t left = 0; left < columns; ++left) {
            for (size_t right = 0; right < columns; ++right) {
                const int64_t score = previous[left * columns + right];
                if (score < 0) continue;
                for (int dl = -1; dl <= 1; ++dl) {
                    const int next_left_signed = (int)left + dl;
                    if (next_left_signed < 0 || next_left_signed >= (int)columns) continue;
                    const size_t next_left = (size_t)next_left_signed;
                    for (int dr = -1; dr <= 1; ++dr) {
                        const int next_right_signed = (int)right + dr;
                        if (next_right_signed < 0 || next_right_signed >= (int)columns) continue;
                        const size_t next_right = (size_t)next_right_signed;
                        int64_t candidate = score + input[2 + row * columns + next_left];
                        if (next_left != next_right) candidate += input[2 + row * columns + next_right];
                        const size_t slot = next_left * columns + next_right;
                        if (candidate > current[slot]) current[slot] = candidate;
                    }
                }
            }
        }
        for (size_t i = 0; i < MAX_DIM * MAX_DIM; ++i) previous[i] = current[i];
    }
    int64_t answer = -1;
    for (size_t left = 0; left < columns; ++left)
        for (size_t right = 0; right < columns; ++right)
            if (previous[left * columns + right] > answer) answer = previous[left * columns + right];
    return answer;
}
