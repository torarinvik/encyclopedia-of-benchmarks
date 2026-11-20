#include <stddef.h>
#include <stdint.h>

enum { MAX_SEQUENCE = 16, MAX_DISTANCE = 32, MAX_OUTPUT = 48, DIAGONAL_OFFSET = 33, DIAGONAL_COUNT = 67 };
enum { MATCH = 0, DELETE = 1, INSERT = 2 };

typedef struct {
    uint8_t operation;
    uint8_t symbol;
} EditStep;

static int build_script(const int64_t *input, uint8_t output[MAX_OUTPUT]) {
    const int n = (int)input[0];
    const int m = (int)input[1];
    const int64_t *first = input + 2;
    const int64_t *second = first + n;
    int frontier[DIAGONAL_COUNT];
    int trace[MAX_DISTANCE + 1][DIAGONAL_COUNT];
    for (int i = 0; i < DIAGONAL_COUNT; ++i) frontier[i] = -1;
    for (int d = 0; d <= MAX_DISTANCE; ++d)
        for (int i = 0; i < DIAGONAL_COUNT; ++i) trace[d][i] = -1;
    frontier[DIAGONAL_OFFSET + 1] = 0;

    int found_d = -1;
    int found_k = 0;
    for (int d = 0; d <= n + m && found_d < 0; ++d) {
        for (int k = -d; k <= d; k += 2) {
            const int slot = DIAGONAL_OFFSET + k;
            int x;
            if (k == -d || (k != d && frontier[slot - 1] < frontier[slot + 1]))
                x = frontier[slot + 1];
            else
                x = frontier[slot - 1] + 1;
            int y = x - k;
            while (x < n && y < m && first[x] == second[y]) { ++x; ++y; }
            frontier[slot] = x;
            trace[d][slot] = x;
            if (x >= n && y >= m) { found_d = d; found_k = k; break; }
        }
    }

    EditStep reverse_path[MAX_DISTANCE];
    int path_length = 0;
    int x = n, y = m, k = found_k;
    for (int d = found_d; d > 0; --d) {
        const int slot = DIAGONAL_OFFSET + k;
        const int *previous = trace[d - 1];
        int previous_k;
        int previous_x;
        int previous_y;
        int snake_x;
        int snake_y;
        if (k == -d || (k != d && previous[slot - 1] < previous[slot + 1])) {
            previous_k = k + 1;
            previous_x = previous[DIAGONAL_OFFSET + previous_k];
            previous_y = previous_x - previous_k;
            snake_x = previous_x;
            snake_y = previous_y + 1;
            while (x > snake_x && y > snake_y) {
                reverse_path[path_length++] = (EditStep){MATCH, 0};
                --x; --y;
            }
            reverse_path[path_length++] = (EditStep){INSERT, (uint8_t)second[previous_y]};
        } else {
            previous_k = k - 1;
            previous_x = previous[DIAGONAL_OFFSET + previous_k];
            previous_y = previous_x - previous_k;
            snake_x = previous_x + 1;
            snake_y = previous_y;
            while (x > snake_x && y > snake_y) {
                reverse_path[path_length++] = (EditStep){MATCH, 0};
                --x; --y;
            }
            reverse_path[path_length++] = (EditStep){DELETE, 0};
        }
        x = previous_x;
        y = previous_y;
        k = previous_k;
    }
    const int prefix = trace[0][DIAGONAL_OFFSET];
    for (int i = 0; i < prefix; ++i) reverse_path[path_length++] = (EditStep){MATCH, 0};

    int bytes = 0;
    for (int i = path_length - 1; i >= 0; --i) {
        const EditStep step = reverse_path[i];
        output[bytes++] = step.operation;
        if (step.operation == INSERT) output[bytes++] = step.symbol;
    }
    return bytes;
}

int64_t myers_ond_shortest_edit_script(const int64_t *input, size_t length,
                                      uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > 2 + 2 * MAX_SEQUENCE) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 0 || n_value > MAX_SEQUENCE || m_value < 0 || m_value > MAX_SEQUENCE)
        return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;

    uint8_t staged[MAX_OUTPUT];
    const int needed = build_script(input, staged);
    if (output == NULL || output_capacity < (size_t)needed) return -2;
    for (int i = 0; i < needed; ++i) output[i] = staged[i];
    return needed;
}
