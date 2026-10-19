#include <stddef.h>
#include <stdint.h>

#define MAX_N 14
#define MAX_DIAGS (2 * MAX_N - 1)
#define EMPTY_OWNER 101
#define MAX_OUTPUT_BYTES 80

typedef struct {
    int n;
    int queen[MAX_N];
    int file[MAX_N];
    int forward_diag[MAX_DIAGS];
    int backward_diag[MAX_DIAGS];
    uint64_t solutions;
} queens_state;

static void find_solutions(queens_state *state, int level)
{
    if (level == state->n) {
        ++state->solutions;
        return;
    }
    for (int file = 0; file < state->n; ++file) {
        const int forward = file + level;
        const int backward = level - file + state->n - 1;
        if (state->file[file] >= level
                && state->forward_diag[forward] >= level
                && state->backward_diag[backward] >= level) {
            state->queen[level] = file;
            state->file[file] = level;
            state->forward_diag[forward] = level;
            state->backward_diag[backward] = level;
            find_solutions(state, level + 1);
            state->file[file] = EMPTY_OWNER;
            state->forward_diag[forward] = EMPTY_OWNER;
            state->backward_diag[backward] = EMPTY_OWNER;
        }
    }
}

static size_t append_literal(uint8_t *output, size_t position, const char *text)
{
    while (*text != '\0') output[position++] = (uint8_t)*text++;
    return position;
}

static size_t append_unsigned(uint8_t *output, size_t position, uint64_t value)
{
    uint8_t reversed[24];
    size_t count = 0;
    do {
        reversed[count++] = (uint8_t)('0' + value % 10u);
        value /= 10u;
    } while (value != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

static size_t render_output(int n, uint64_t solutions, uint8_t *output)
{
    size_t position = append_unsigned(output, 0, (uint64_t)n);
    position = append_literal(output, position, n == 1 ? " queen on a " : " queens on a ");
    position = append_unsigned(output, position, (uint64_t)n);
    output[position++] = (uint8_t)'x';
    position = append_unsigned(output, position, (uint64_t)n);
    position = append_literal(output, position, " board...\n");
    if (solutions == 1) {
        position = append_literal(output, position, "...there is 1 solution\n");
    } else {
        position = append_literal(output, position, "...there are ");
        position = append_unsigned(output, position, solutions);
        position = append_literal(output, position, " solutions\n");
    }
    return position;
}

int64_t queens(int64_t n, uint8_t *output, size_t output_capacity)
{
    if (n < 1 || n > MAX_N) return -1;

    queens_state state = {0};
    state.n = (int)n;
    for (int file = 0; file < MAX_N; ++file) state.file[file] = EMPTY_OWNER;
    for (int diagonal = 0; diagonal < MAX_DIAGS; ++diagonal) {
        state.forward_diag[diagonal] = EMPTY_OWNER;
        state.backward_diag[diagonal] = EMPTY_OWNER;
    }
    find_solutions(&state, 0);

    uint8_t formatted[MAX_OUTPUT_BYTES];
    const size_t required = render_output(state.n, state.solutions, formatted);
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < required; ++index) output[index] = formatted[index];
    return (int64_t)required;
}
