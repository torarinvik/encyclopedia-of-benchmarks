module sliding_window_aggregator;

const long INVALID_RESULT = -9223372036854775807 - 1;
const long MAX_VALUE = 1_000_000;
const usz MAX_PARSEABLE_INPUT_LENGTH = 259;

fn long sliding_window_aggregator(long* input, usz length) @export("sliding_window_aggregator") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 256) return INVALID_RESULT;

    usz capacity = (usz)input[0];
    usz count = (usz)input[1];
    if (length != count + 2) return INVALID_RESULT;
    for (usz index = 0; index < count; ++index) {
        if (input[index + 2] < -MAX_VALUE || input[index + 2] > MAX_VALUE) return INVALID_RESULT;
    }

    long window[64] = {0};
    usz head = 0;
    usz size = 0;
    long sum = 0;
    for (usz index = 0; index < count; ++index) {
        long value = input[index + 2];
        if (size < capacity) {
            usz tail = (head + size) % capacity;
            window[tail] = value;
            sum += value;
            size += 1;
        } else {
            sum -= window[head];
            window[head] = value;
            sum += value;
            head = (head + 1) % capacity;
        }
    }
    return sum;
}
