module second_min_max;

const long INVALID_RESULT = -9223372036854775807L - 1;
const long INT32_MIN_VALUE = -2147483648;
const long INT32_MAX_VALUE = 2147483647;
const usz MAX_INPUT_LENGTH = 259;

fn long second_min_max(long* input, usz length) @export("second_min_max") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = input[0], raw_count = input[1];
    if ((operation != 0 && operation != 1) || raw_count < 2 || raw_count > 256) return INVALID_RESULT;
    usz count = (usz)raw_count;
    if (length != count + 2) return INVALID_RESULT;
    long initial = operation == 0 ? INT32_MAX_VALUE : INT32_MIN_VALUE;
    long best = initial, second = initial;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 2];
        if (value < INT32_MIN_VALUE || value > INT32_MAX_VALUE) return INVALID_RESULT;
        bool better = operation == 0 ? value < best : value > best;
        if (better) {
            second = best;
            best = value;
        } else {
            bool improves_second = operation == 0 ? value < second : value > second;
            if (improves_second && value != best) second = value;
        }
    }
    return second == initial ? INVALID_RESULT : second;
}
