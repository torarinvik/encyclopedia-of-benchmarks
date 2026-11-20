module ryser_permanent;

const usz MAX_DIMENSION = 8;
const usz MAX_INPUT_LENGTH = 65;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn usz bit_count(usz value) {
    usz count = 0;
    while (value != 0) {
        count += value & 1;
        value >>= 1;
    }
    return count;
}

fn long ryser_permanent(long* input, usz length)
        @export("ryser_permanent") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz n = (usz)input[0];
    if (length != 1 + n * n) return INVALID_RESULT;

    for (usz index = 0; index < n * n; ++index) {
        long value = input[1 + index];
        if (value < -4 || value > 4) return INVALID_RESULT;
    }

    long[MAX_DIMENSION] row_sums = {};
    long total = 0;
    usz previous_gray = 0;
    usz subset_count = 1 << n;
    for (usz ordinal = 0; ordinal < subset_count; ++ordinal) {
        usz gray = ordinal ^ (ordinal >> 1);
        if (ordinal != 0) {
            usz changed = gray ^ previous_gray;
            usz column = 0;
            while (((changed >> column) & 1) == 0) ++column;
            long direction = (gray & changed) != 0 ? 1 : -1;
            for (usz row = 0; row < n; ++row) {
                row_sums[row] += direction * input[1 + row * n + column];
            }
        }

        long product = 1;
        for (usz row = 0; row < n; ++row) product *= row_sums[row];
        if (((n + bit_count(gray)) & 1) != 0) product = -product;
        total += product;
        previous_gray = gray;
    }
    return total;
}
