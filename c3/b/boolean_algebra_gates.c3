module boolean_algebra_gates;

const usz MAX_INPUT_COUNT = 4096;
const long INVALID_RESULT = -1;

fn long boolean_algebra_gates(long* values, usz length) @export("boolean_algebra_gates") {
    if (values == null || length < 2 || length > MAX_INPUT_COUNT + 2) return INVALID_RESULT;
    long gate = values[0];
    long count = values[1];
    if (gate < 0 || gate > 5 || count < 0 || count > 4096) return INVALID_RESULT;
    if ((usz)count != length - 2) return INVALID_RESULT;
    if (gate == 2 && count != 1) return INVALID_RESULT;
    long result = (gate == 0 || gate == 4) ? 1 : 0;
    for (usz index = 0; index < (usz)count; index++) {
        long bit = values[index + 2];
        if (bit != 0 && bit != 1) return INVALID_RESULT;
        if (gate == 0 || gate == 4) result &= bit;
        else if (gate == 1 || gate == 5) result |= bit;
        else if (gate == 2) result = 1 - bit;
        else result ^= bit;
    }
    if (gate == 4 || gate == 5) result = 1 - result;
    return result;
}
