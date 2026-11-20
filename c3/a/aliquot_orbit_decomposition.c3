module aliquot_orbit_decomposition;

const usz MAX_TERMS = 4097;
const usz MAX_INPUT = 3;
const long MAX_SEED = 100000;
const long MAX_VALUE = 100000;
const long MAX_TRANSITIONS = 4096;

fn long aliquot_sum(long value) {
    if (value == 1) return 0;
    long sum = 1;
    for (long d = 2; d <= value / d; d++) {
        if (value % d == 0) {
            sum += d;
            long partner = value / d;
            if (partner != d) sum += partner;
        }
    }
    return sum;
}

fn void store_i64(char* output, usz offset, long value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long aliquot_orbit_decomposition(long* input, usz length, char* output, usz capacity)
    @export("aliquot_orbit_decomposition") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    if (length != 2 || input[0] < 1 || input[0] > MAX_SEED ||
        input[1] < 1 || input[1] > MAX_TRANSITIONS) return -1;

    long[MAX_TERMS] keys;
    long[MAX_TERMS] first_indices;
    usz key_count = 0;
    long[3] words;
    long current = input[0];
    long transitions = 0;
    long positive_term_count = 0;

    while (true) {
        if (current == 0) {
            words[0] = 0; words[1] = positive_term_count; words[2] = 0;
            break;
        }
        usz low = 0, high = key_count;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (keys[middle] < current) low = middle + 1; else high = middle;
        }
        if (low < key_count && keys[low] == current) {
            words[0] = 1;
            words[1] = first_indices[low];
            words[2] = transitions - first_indices[low];
            break;
        }
        for (usz i = key_count; i > low; i--) {
            keys[i] = keys[i - 1]; first_indices[i] = first_indices[i - 1];
        }
        keys[low] = current; first_indices[low] = transitions;
        key_count++; positive_term_count++;
        if (transitions >= input[1]) {
            words[0] = -3; words[1] = transitions; words[2] = current;
            break;
        }
        long next_value = aliquot_sum(current);
        transitions++;
        if (next_value > MAX_VALUE) {
            words[0] = -2; words[1] = transitions; words[2] = next_value;
            break;
        }
        current = next_value;
    }

    if (output == null || capacity < 24) return -2;
    for (usz word = 0; word < 3; word++) store_i64(output, word * 8, words[word]);
    return 24;
}
