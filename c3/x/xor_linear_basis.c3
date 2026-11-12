module xor_linear_basis;

const int MAX_OPERATIONS = 64;
const int MAX_INSERTIONS = 16;
const usz MAX_INPUT_VALUES = 1 + 2 * MAX_OPERATIONS;
const int BIT_COUNT = 63;

fn void insert_value(ulong[BIT_COUNT]* basis, ulong value) {
    for (int bit = BIT_COUNT - 1; bit >= 0 && value != 0; bit--) {
        if (((value >> bit) & 1) == 0) continue;
        if (basis[bit] == 0) { basis[bit] = value; return; }
        value ^= basis[bit];
    }
}

fn ulong maximum_value(ulong[BIT_COUNT] basis) {
    ulong best = 0;
    for (int bit = BIT_COUNT - 1; bit >= 0; bit--) {
        ulong candidate = best ^ basis[bit];
        if (candidate > best) best = candidate;
    }
    return best;
}

fn bool contains_value(ulong[BIT_COUNT] basis, ulong value) {
    for (int bit = BIT_COUNT - 1; bit >= 0; bit--) {
        if (((value >> bit) & 1) == 0) continue;
        if (basis[bit] == 0) return false;
        value ^= basis[bit];
    }
    return value == 0;
}

fn void store_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long xor_linear_basis(long* input, usz length, char* output, usz capacity)
    @export("xor_linear_basis") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long q_value = input[0];
    if (q_value < 1 || q_value > MAX_OPERATIONS) return -1;
    int q = (int)q_value;

    ulong[BIT_COUNT] basis = zeroed;
    long[MAX_OPERATIONS] results;
    usz result_count = 0, cursor = 1, insertion_count = 0;
    for (int operation = 0; operation < q; operation++) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        if (kind == 0 || kind == 2) {
            if (cursor >= length) return -1;
            long raw_value = input[cursor++];
            if (raw_value < 0) return -1;
            ulong value = (ulong)raw_value;
            if (kind == 0) {
                insertion_count++;
                if (insertion_count > MAX_INSERTIONS) return -1;
                insert_value(&basis, value);
            } else {
                results[result_count++] = contains_value(basis, value) ? 1 : 0;
            }
        } else if (kind == 1) {
            results[result_count++] = (long)maximum_value(basis);
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;
    usz output_bytes = result_count * 8;
    if (output_bytes == 0) return 0;
    if (output == null || capacity < output_bytes) return -2;
    for (usz result = 0; result < result_count; result++)
        store_le(output, result * 8, results[result]);
    return (long)output_bytes;
}
