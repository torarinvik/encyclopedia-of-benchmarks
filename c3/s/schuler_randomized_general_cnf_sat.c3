module schuler_randomized_general_cnf_sat;

const int MAX_N = 6;
const int MAX_M = 4;
const int MAX_CALLS = 7;
const usz MAX_INPUT = 122;

fn int lit_var(long literal) { return (int)(literal > 0 ? literal : -literal) - 1; }
fn bool lit_true(long literal, int value) { return literal > 0 ? value == 1 : value == 0; }

fn int prefix_size(int clauses) {
    int bits = 0;
    while (clauses > 0) { bits++; clauses >>= 1; }
    return bits + 1;
}

fn bool ppz(int n, int m, long[MAX_M][MAX_N] formula, int[MAX_M] lengths,
            int[MAX_N] fixed, int[MAX_N] permutation, int[MAX_N] bits,
            int[MAX_N] local, int* units, int* guesses) {
    int[MAX_N] active = {};
    int active_count = 0;
    for (int variable = 0; variable < n; variable++) local[variable] = -1;
    for (int position = 0; position < n; position++) {
        int variable = permutation[position] - 1;
        if (fixed[variable] < 0) active[active_count++] = variable;
    }

    long[MAX_M][MAX_N] work = {};
    int[MAX_M] work_lengths = {};
    for (int clause = 0; clause < m; clause++) {
        work_lengths[clause] = lengths[clause];
        for (int item = 0; item < lengths[clause]; item++) work[clause][item] = formula[clause][item];
    }
    for (int offset = 0; offset < active_count; offset++) {
        int variable = active[offset];
        bool positive_unit = false, negative_unit = false;
        for (int clause = 0; clause < m; clause++) if (work_lengths[clause] == 1) {
            if (work[clause][0] == variable + 1) positive_unit = true;
            if (work[clause][0] == -(variable + 1)) negative_unit = true;
        }
        int value;
        if (positive_unit) { value = 1; (*units)++; }
        else if (negative_unit) { value = 0; (*units)++; }
        else { value = bits[offset]; (*guesses)++; }
        local[variable] = value;

        long[MAX_M][MAX_N] next = {};
        int[MAX_M] next_lengths = {};
        int next_m = 0;
        for (int clause = 0; clause < m; clause++) {
            bool satisfied = false;
            int out_length = 0;
            for (int item = 0; item < work_lengths[clause]; item++) {
                long literal = work[clause][item];
                if (lit_var(literal) != variable) next[next_m][out_length++] = literal;
                else if (lit_true(literal, value)) { satisfied = true; break; }
            }
            if (!satisfied) next_lengths[next_m++] = out_length;
        }
        for (int clause = 0; clause < next_m; clause++) {
            work_lengths[clause] = next_lengths[clause];
            for (int item = 0; item < next_lengths[clause]; item++) work[clause][item] = next[clause][item];
        }
        m = next_m;
    }
    for (int clause = 0; clause < m; clause++) if (work_lengths[clause] == 0) return false;
    true
}

fn void put_i64(uint8 *output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[8 * word + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long schuler_randomized_general_cnf_sat(long *input, usz length, uint8 *output,
                                           usz capacity) @export("schuler_randomized_general_cnf_sat") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M) return -1;
    int n = (int)n0, original_m = (int)m0;
    long[MAX_M][MAX_N] formula = {};
    int[MAX_M] lengths = {};
    usz position = 2;
    for (int clause = 0; clause < original_m; clause++) {
        if (position >= length) return -1;
        long size0 = input[position++];
        if (size0 < 1 || size0 > n || position + (usz)size0 > length) return -1;
        bool[MAX_N] seen = {};
        lengths[clause] = (int)size0;
        for (int item = 0; item < lengths[clause]; item++) {
            long literal = input[position++];
            if (literal == 0 || literal < -n || literal > n) return -1;
            int variable = lit_var(literal);
            if (seen[variable]) return -1;
            seen[variable] = true;
            formula[clause][item] = literal;
        }
    }

    int[MAX_CALLS][MAX_N] permutations = {};
    int[MAX_CALLS][MAX_N] random_bits = {};
    int[MAX_CALLS] choices = {};
    for (int call = 0; call <= n; call++) {
        bool[MAX_N] seen = {};
        for (int item = 0; item < n; item++) {
            if (position >= length) return -1;
            long value = input[position++];
            if (value < 1 || value > n || seen[(int)value - 1]) return -1;
            seen[(int)value - 1] = true;
            permutations[call][item] = (int)value;
        }
        for (int item = 0; item < n; item++) {
            if (position >= length || (input[position] != 0 && input[position] != 1)) return -1;
            random_bits[call][item] = (int)input[position++];
        }
        if (position >= length) return -1;
        long choice = input[position++];
        if (choice < 0 || choice >= m0) return -1;
        choices[call] = (int)choice;
    }
    if (position != length) return -1;

    int[MAX_N] fixed = {};
    for (int variable = 0; variable < n; variable++) fixed[variable] = -1;
    long[MAX_M][MAX_N] current = {};
    int[MAX_M] current_lengths = {};
    int current_m = original_m;
    for (int clause = 0; clause < current_m; clause++) {
        current_lengths[clause] = lengths[clause];
        for (int item = 0; item < lengths[clause]; item++) current[clause][item] = formula[clause][item];
    }

    int calls = 0, units = 0, guesses = 0, max_depth = 0;
    int found = 0, mask = 0, depth = 0;
    while (true) {
        calls++;
        if (depth > max_depth) max_depth = depth;
        if (current_m == 0) {
            found = 1;
            for (int variable = 0; variable < n; variable++) if (fixed[variable] == 1) mask |= 1 << variable;
            break;
        }
        int k = prefix_size(current_m);
        long[MAX_M][MAX_N] shortened = {};
        int[MAX_M] short_lengths = {};
        for (int clause = 0; clause < current_m; clause++) {
            short_lengths[clause] = current_lengths[clause] < k ? current_lengths[clause] : k;
            for (int item = 0; item < short_lengths[clause]; item++) shortened[clause][item] = current[clause][item];
        }
        int[MAX_N] local = {};
        bool success = ppz(n, current_m, shortened, short_lengths, fixed,
                           permutations[depth], random_bits[depth], local, &units, &guesses);
        if (success) {
            found = 1;
            for (int variable = 0; variable < n; variable++)
                if (fixed[variable] == 1 || (fixed[variable] < 0 && local[variable] == 1)) mask |= 1 << variable;
            break;
        }
        int[MAX_M] eligible = {};
        int eligible_count = 0;
        for (int clause = 0; clause < current_m; clause++)
            if (short_lengths[clause] == k) eligible[eligible_count++] = clause;
        if (eligible_count == 0) break;
        if (choices[depth] >= eligible_count) return -1;
        int selected = eligible[choices[depth]];
        int[MAX_N] next_fixed = {};
        for (int variable = 0; variable < n; variable++) next_fixed[variable] = fixed[variable];
        for (int item = 0; item < k; item++) {
            long literal = shortened[selected][item];
            next_fixed[lit_var(literal)] = literal > 0 ? 0 : 1;
        }
        long[MAX_M][MAX_N] next = {};
        int[MAX_M] next_lengths = {};
        int next_m = 0;
        for (int clause = 0; clause < current_m; clause++) {
            bool satisfied = false;
            int out_length = 0;
            for (int item = 0; item < current_lengths[clause]; item++) {
                long literal = current[clause][item];
                int value = next_fixed[lit_var(literal)];
                if (value < 0) next[next_m][out_length++] = literal;
                else if (lit_true(literal, value)) { satisfied = true; break; }
            }
            if (!satisfied) next_lengths[next_m++] = out_length;
        }
        for (int clause = 0; clause < next_m; clause++) {
            current_lengths[clause] = next_lengths[clause];
            for (int item = 0; item < next_lengths[clause]; item++) current[clause][item] = next[clause][item];
        }
        current_m = next_m;
        for (int variable = 0; variable < n; variable++) fixed[variable] = next_fixed[variable];
        depth++;
        if (depth > n) return -1;
    }
    if (!found) mask = 0;
    long[6] staged = {(long)found, (long)mask, (long)calls, (long)units, (long)guesses, (long)max_depth};
    if (output == null || capacity < 48) return -2;
    for (usz word = 0; word < 6; word++) put_i64(output, word, staged[word]);
    return 48;
}
