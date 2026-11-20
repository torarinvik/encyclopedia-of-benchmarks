module penney_game_pattern_probability;

const long MODULUS = 998244353;
const usz MAX_STATES = 7;

fn long pow_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn int find_state(long[MAX_STATES] codes, long[MAX_STATES] lengths,
                  usz count, long code, long length) {
    for (usz index = 0; index < count; ++index)
        if (codes[index] == code && lengths[index] == length) return (int)index;
    return -1;
}

fn long solve(long word_length, long first, long second) {
    long[MAX_STATES] codes = zeroed;
    long[MAX_STATES] lengths = zeroed;
    usz state_count = 1;
    for (long prefix_length = 1; prefix_length < word_length; ++prefix_length) {
        for (usz which = 0; which < 2; ++which) {
            long pattern = which == 0 ? first : second;
            long code = pattern >> (word_length - prefix_length);
            if (find_state(codes, lengths, state_count, code, prefix_length) < 0) {
                codes[state_count] = code;
                lengths[state_count] = prefix_length;
                ++state_count;
            }
        }
    }

    long[MAX_STATES][MAX_STATES + 1] matrix = zeroed;
    for (usz row = 0; row < state_count; ++row) {
        for (usz column = 0; column < state_count; ++column)
            matrix[row][column] = row == column ? 2 : 0;
        for (long bit = 0; bit <= 1; ++bit) {
            long candidate = (codes[row] << 1) | bit;
            long candidate_length = lengths[row] + 1;
            if (candidate_length == word_length && candidate == first) {
                ++matrix[row][state_count];
                continue;
            }
            if (candidate_length == word_length && candidate == second) continue;

            long suffix_length = candidate_length;
            if (suffix_length > word_length - 1) suffix_length = word_length - 1;
            int destination = -1;
            while (suffix_length >= 0 && destination < 0) {
                long suffix_mask = ((long)1 << suffix_length) - 1;
                destination = find_state(codes, lengths, state_count,
                    candidate & suffix_mask, suffix_length);
                --suffix_length;
            }
            if (destination < 0) destination = 0;
            usz target = (usz)destination;
            matrix[row][target] = (matrix[row][target] - 1 + MODULUS) % MODULUS;
        }
    }

    for (usz column = 0; column < state_count; ++column) {
        usz pivot = column;
        while (pivot < state_count && matrix[pivot][column] == 0) ++pivot;
        if (pivot == state_count) return -1;
        if (pivot != column)
            for (usz j = 0; j <= state_count; ++j) {
                long temporary = matrix[column][j];
                matrix[column][j] = matrix[pivot][j];
                matrix[pivot][j] = temporary;
            }
        long inverse = pow_mod(matrix[column][column], MODULUS - 2);
        for (usz j = column; j <= state_count; ++j)
            matrix[column][j] = matrix[column][j] * inverse % MODULUS;
        for (usz row = 0; row < state_count; ++row) {
            if (row == column) continue;
            long factor = matrix[row][column];
            for (usz j = column; j <= state_count; ++j) {
                long product = factor * matrix[column][j] % MODULUS;
                matrix[row][j] = (matrix[row][j] - product + MODULUS) % MODULUS;
            }
        }
    }
    return matrix[0][state_count];
}

fn long penney_game_pattern_probability(long* input, usz length)
    @export("penney_game_pattern_probability") {
    if (input == null || length != 3) return -1;
    long word_length = input[0];
    if (word_length < 1 || word_length > 4) return -1;
    long limit = (long)1 << word_length;
    long first = input[1], second = input[2];
    if (first < 0 || second < 0 || first >= limit || second >= limit || first == second)
        return -1;
    return solve(word_length, first, second);
}
