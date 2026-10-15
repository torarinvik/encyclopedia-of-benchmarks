module average;

const usz MAX_INPUT_LENGTH = 4096;
const long MAX_ABS_VALUE = 1000000000;
const double INVALID_RESULT = -1.0e300;

fn double average(long* values, usz length) @export("average") {
    if (length == 0 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long sum = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += value;
    }
    return (double)sum / (double)length;
}
