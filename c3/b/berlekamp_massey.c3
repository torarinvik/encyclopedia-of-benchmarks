module berlekamp_massey;

const long MODULUS = 998244353;
const int MAX_ORDER = 8;
const int MAX_TERMS = 2 * MAX_ORDER;
const usz MAX_INPUT_VALUES = 1 + MAX_TERMS + 1;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long multiply(long left, long right) {
    return (left * right) % MODULUS;
}

fn long power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn int infer_recurrence(long* sequence, int term_count, long* coefficients) {
    long[MAX_TERMS + 1] current = zeroed;
    long[MAX_TERMS + 1] previous = zeroed;
    long[MAX_TERMS + 1] old = zeroed;
    int current_length = 0;
    int previous_length = 0;
    int last_index = -1;
    long last_discrepancy = 0;

    for (int index = 0; index < term_count; index += 1) {
        long predicted = 0;
        int lag = 0;
        while (lag < current_length && lag < index) {
            predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]));
            lag += 1;
        }
        long discrepancy = normalize(sequence[index] - predicted);
        if (discrepancy == 0) continue;

        if (last_index < 0) {
            last_index = index;
            last_discrepancy = discrepancy;
            current_length = index + 1;
            for (lag = 0; lag < current_length; lag += 1) current[lag] = 0;
            continue;
        }

        for (lag = 0; lag < current_length; lag += 1) old[lag] = current[lag];
        int old_length = current_length;
        int shift = index - last_index;
        long scale = multiply(discrepancy, power(last_discrepancy, MODULUS - 2));
        int needed_length = previous_length + shift;
        if (current_length < needed_length) {
            for (lag = current_length; lag < needed_length; lag += 1) current[lag] = 0;
            current_length = needed_length;
        }
        current[shift - 1] = normalize(current[shift - 1] + scale);
        for (lag = 0; lag < previous_length; lag += 1)
            current[shift + lag] = normalize(current[shift + lag] - multiply(scale, previous[lag]));

        if (old_length - index < previous_length - last_index) {
            for (lag = 0; lag < old_length; lag += 1) previous[lag] = old[lag];
            previous_length = old_length;
            last_index = index;
            last_discrepancy = discrepancy;
        }
    }

    for (int lag = 0; lag < current_length; lag += 1) coefficients[lag] = current[lag];
    return current_length;
}

fn long berlekamp_massey(long* input, usz length, char* output, usz capacity)
    @export("berlekamp_massey") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long bound_value = input[0];
    if (bound_value < 1 || bound_value > MAX_ORDER) return -1;
    int bound = (int)bound_value;
    int term_count = 2 * bound;
    if (length != (usz)(1 + term_count)) return -1;

    long[MAX_TERMS] sequence = zeroed;
    for (int index = 0; index < term_count; index += 1) {
        long value = input[1 + index];
        if (value < 0 || value >= MODULUS) return -1;
        sequence[index] = value;
    }
    long[MAX_TERMS + 1] coefficients = zeroed;
    int order = infer_recurrence(&sequence[0], term_count, &coefficients[0]);
    if (order > bound) return -1;

    usz output_bytes = (usz)(8 * (order + 1));
    if (output == null || capacity < output_bytes) return -2;
    store_i64_le(output, (long)order);
    for (int lag = 0; lag < order; lag += 1)
        store_i64_le(output + 8 * (lag + 1), coefficients[lag]);
    return (long)output_bytes;
}
