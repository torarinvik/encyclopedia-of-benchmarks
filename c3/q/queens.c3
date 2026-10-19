module queens;

const usz MAX_N = 14;
const usz MAX_DIAGS = 2 * MAX_N - 1;
const int EMPTY_OWNER = 101;
const usz MAX_OUTPUT_BYTES = 80;

struct QueensState {
    int n;
    int[MAX_N] queen;
    int[MAX_N] file;
    int[MAX_DIAGS] forward_diag;
    int[MAX_DIAGS] backward_diag;
    ulong solutions;
}

fn void find_solutions(QueensState* state, int level) {
    if (level == state.n) {
        state.solutions++;
        return;
    }
    for (int file = 0; file < state.n; file++) {
        int forward = file + level;
        int backward = level - file + state.n - 1;
        if (state.file[file] >= level && state.forward_diag[forward] >= level &&
            state.backward_diag[backward] >= level) {
            state.queen[level] = file;
            state.file[file] = level;
            state.forward_diag[forward] = level;
            state.backward_diag[backward] = level;
            find_solutions(state, level + 1);
            state.file[file] = EMPTY_OWNER;
            state.forward_diag[forward] = EMPTY_OWNER;
            state.backward_diag[backward] = EMPTY_OWNER;
        }
    }
}

fn usz append_literal(char* output, usz position, const char* text) {
    for (usz index = 0; text[index] != 0; index++) output[position++] = text[index];
    return position;
}

fn usz append_unsigned(char* output, usz position, ulong value) {
    char[24] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)('0' + value % 10ul);
        value /= 10ul;
    } while (value != 0);
    while (count > 0) { count--; output[position++] = reversed[count]; }
    return position;
}

fn usz render_output(int n, ulong solutions, char* output) {
    usz position = append_unsigned(output, 0, (ulong)n);
    position = append_literal(output, position, n == 1 ? " queen on a " : " queens on a ");
    position = append_unsigned(output, position, (ulong)n);
    output[position++] = 'x';
    position = append_unsigned(output, position, (ulong)n);
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

fn long queens(long n, char* output, usz output_capacity) @export("queens") {
    if (n < 1 || n > 14) return -1;

    QueensState state = {};
    state.n = (int)n;
    for (int file = 0; file < (int)MAX_N; file++) state.file[file] = EMPTY_OWNER;
    for (int diagonal = 0; diagonal < (int)MAX_DIAGS; diagonal++) {
        state.forward_diag[diagonal] = EMPTY_OWNER;
        state.backward_diag[diagonal] = EMPTY_OWNER;
    }
    find_solutions(&state, 0);

    char[MAX_OUTPUT_BYTES] formatted = {};
    usz required = render_output(state.n, state.solutions, &formatted[0]);
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < required; index++) output[index] = formatted[index];
    return (long)required;
}
