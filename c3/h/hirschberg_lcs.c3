module hirschberg_lcs;

const usz MAX_SEQUENCE_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 132;

struct HirschbergState {
    int[MAX_SEQUENCE_LENGTH + 1] forward;
    int[MAX_SEQUENCE_LENGTH + 1] backward;
    char[MAX_SEQUENCE_LENGTH] result;
    usz result_length;
}

fn void lcs_row(long* input, usz a_base, usz a0, usz a1,
                usz b_base, usz b0, usz b1, bool reverse_a, bool reverse_b,
                int* row) {
    usz width = b1 - b0;
    for (usz j = 0; j <= width; ++j) row[j] = 0;
    for (usz i = 0; i < a1 - a0; ++i) {
        long av = input[a_base + (reverse_a ? a1 - 1 - i : a0 + i)];
        int diagonal = 0;
        for (usz j = 1; j <= width; ++j) {
            int above = row[j];
            long bv = input[b_base + (reverse_b ? b1 - j : b0 + j - 1)];
            if (av == bv) row[j] = diagonal + 1;
            else if (row[j - 1] > row[j]) row[j] = row[j - 1];
            diagonal = above;
        }
    }
}

fn void recover_lcs(long* input, usz a_base, usz a0, usz a1,
                    usz b_base, usz b0, usz b1, HirschbergState* state) {
    usz a_length = a1 - a0;
    usz b_length = b1 - b0;
    if (a_length == 0 || b_length == 0) return;
    if (a_length == 1) {
        long target = input[a_base + a0];
        for (usz j = b0; j < b1; ++j) {
            if (input[b_base + j] == target) {
                state.result[state.result_length++] = (char)target;
                return;
            }
        }
        return;
    }

    usz middle = a0 + a_length / 2;
    lcs_row(input, a_base, a0, middle, b_base, b0, b1, false, false, &state.forward[0]);
    lcs_row(input, a_base, middle, a1, b_base, b0, b1, true, true, &state.backward[0]);
    usz split = 0;
    int best_score = -1;
    for (usz j = 0; j <= b_length; ++j) {
        int score = state.forward[j] + state.backward[b_length - j];
        if (score > best_score) {
            best_score = score;
            split = j;
        }
    }
    recover_lcs(input, a_base, a0, middle, b_base, b0, b0 + split, state);
    recover_lcs(input, a_base, middle, a1, b_base, b0 + split, b1, state);
}

fn long hirschberg_lcs(long* input, usz length, char* output, usz capacity)
        @export("hirschberg_lcs") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_SEQUENCE_LENGTH
        || input[1] < 0 || input[1] > (long)MAX_SEQUENCE_LENGTH) return -1;
    usz first_length = (usz)input[0];
    usz second_length = (usz)input[1];
    if (length != 2 + first_length + second_length) return -1;
    for (usz i = 0; i < first_length + second_length; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    HirschbergState state;
    state.result_length = 0;
    usz a_base = 2;
    usz b_base = 2 + first_length;
    usz a_length = first_length;
    usz b_length = second_length;
    if (a_length < b_length) {
        a_base = 2 + first_length;
        b_base = 2;
        a_length = second_length;
        b_length = first_length;
    }
    recover_lcs(input, a_base, 0, a_length, b_base, 0, b_length, &state);
    if (output == null || capacity < state.result_length) return -2;
    for (usz i = 0; i < state.result_length; ++i) output[i] = state.result[i];
    return (long)state.result_length;
}
