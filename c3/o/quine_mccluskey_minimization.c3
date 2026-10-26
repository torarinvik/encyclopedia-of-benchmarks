module quine_mccluskey_minimization;

const MAX_VARIABLES = 3;
const MAX_CUBES = 27;
const MAX_STATES = 256;
const MAX_INPUT_LENGTH = 9;
const INF = 99;

fn bool cube_valid(usz care, usz value, long* status, usz size) {
    usz cover = 0;
    for (usz minterm = 0; minterm < size; minterm++) {
        if ((minterm & care) == value) {
            if (status[minterm] == 0) return false;
            if (status[minterm] == 1) cover |= 1 << minterm;
        }
    }
    return cover != 0;
}

fn bool lex_better(ulong candidate, ulong incumbent, usz count) {
    for (usz index = 0; index < count; index++) {
        ulong bit = 1 << index;
        bool left = (candidate & bit) != 0;
        bool right = (incumbent & bit) != 0;
        if (left != right) return left;
    }
    return false;
}

fn long quine_mccluskey_minimization(long* input, usz length, char* output, usz capacity) @export("quine_mccluskey_minimization") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VARIABLES) return -1;
    usz n = (usz)input[0];
    usz size = 1 << n;
    if (length != 1 + size) return -1;
    for (usz minterm = 0; minterm < size; minterm++) {
        if (input[1 + minterm] < 0 || input[1 + minterm] > 2) return -1;
    }

    usz[MAX_CUBES] cares;
    usz[MAX_CUBES] values;
    usz[MAX_CUBES] covers;
    usz[MAX_CUBES] literal_counts;
    usz prime_count = 0;
    usz full = size - 1;
    for (usz care = 0; care <= full; care++) {
        for (usz value = 0; value <= full; value++) {
            if ((value & ~care) != 0 || !cube_valid(care, value, input + 1, size)) continue;
            bool prime = true;
            for (usz variable = 0; variable < n; variable++) {
                usz bit = 1 << variable;
                if ((care & bit) != 0 && cube_valid(care ^ bit, value & ~bit, input + 1, size)) {
                    prime = false;
                    break;
                }
            }
            if (!prime) continue;
            usz cover = 0;
            usz literal_count = 0;
            for (usz minterm = 0; minterm < size; minterm++) {
                if ((minterm & care) == value && input[1 + minterm] == 1) cover |= 1 << minterm;
            }
            for (usz bit_index = 0; bit_index < n; bit_index++) if ((care & (1 << bit_index)) != 0) literal_count++;
            cares[prime_count] = care;
            values[prime_count] = value;
            covers[prime_count] = cover;
            literal_counts[prime_count] = literal_count;
            prime_count++;
        }
    }

    usz on_mask = 0;
    for (usz minterm = 0; minterm < size; minterm++) if (input[1 + minterm] == 1) on_mask |= 1 << minterm;
    usz state_count = 1 << size;
    usz[MAX_STATES] term_cost;
    usz[MAX_STATES] literal_cost;
    ulong[MAX_STATES] selected;
    for (usz state = 0; state < state_count; state++) {
        term_cost[state] = INF;
        literal_cost[state] = INF;
        selected[state] = 0;
    }
    term_cost[0] = 0;
    literal_cost[0] = 0;
    for (usz index = 0; index < prime_count; index++) {
        ulong prime_bit = 1 << index;
        usz state = state_count;
        while (state > 0) {
            state--;
            if (term_cost[state] == INF) continue;
            usz destination = state | covers[index];
            if (destination == state) continue;
            usz new_terms = term_cost[state] + 1;
            usz new_literals = literal_cost[state] + literal_counts[index];
            ulong new_selected = selected[state] | prime_bit;
            bool better = new_terms < term_cost[destination];
            if (new_terms == term_cost[destination]) {
                better = new_literals < literal_cost[destination];
                if (new_literals == literal_cost[destination]) better = lex_better(new_selected, selected[destination], prime_count);
            }
            if (better) {
                term_cost[destination] = new_terms;
                literal_cost[destination] = new_literals;
                selected[destination] = new_selected;
            }
        }
    }
    ulong chosen = selected[on_mask];
    usz term_count = 0;
    for (usz index = 0; index < prime_count; index++) if ((chosen & (1 << index)) != 0) term_count++;
    usz output_bytes = 8 * (1 + 2 * term_count);
    if (output == null || capacity < output_bytes) return -2;
    long[17] words;
    words[0] = (long)term_count;
    usz cursor = 1;
    for (usz index = 0; index < prime_count; index++) {
        if ((chosen & (1 << index)) != 0) {
            words[cursor++] = (long)cares[index];
            words[cursor++] = (long)values[index];
        }
    }
    for (usz word = 0; word < cursor; word++) {
        ulong bits = (ulong)words[word];
        for (usz byte = 0; byte < 8; byte++) {
            output[word * 8 + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}
