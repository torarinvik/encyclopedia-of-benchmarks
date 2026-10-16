module value_at_risk;

const long SCALE = 1000000;
const usz MAX_RETURNS = 64;
const usz MAX_PARSED_RETURNS = 65;
const long MAX_SAMPLE = 1000000000;
const usz MAX_INPUT_LENGTH = 67;
const double INVALID_RESULT = -1.0e300;

fn void sift_down(double* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        double temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(double* values, usz length) {
    for (usz start = length / 2; start > 0; start--) sift_down(values, start - 1, length);
    for (usz end = length; end > 1; end--) {
        double temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

fn double value_at_risk(long* input, usz length) @export("value_at_risk") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long confidence_micro = input[0], count_value = input[1];
    if (confidence_micro < 1 || confidence_micro >= SCALE || count_value < 1 || count_value > (long)MAX_PARSED_RETURNS)
        return INVALID_RESULT;
    if (length != 2 + (usz)count_value || count_value > (long)MAX_RETURNS) return INVALID_RESULT;
    usz count = (usz)count_value;
    double[MAX_RETURNS] returns;
    for (usz i = 0; i < count; i++) {
        long value = input[2 + i];
        if (value < -MAX_SAMPLE || value > MAX_SAMPLE) return INVALID_RESULT;
        returns[i] = (double)value / (double)SCALE;
    }
    heap_sort(&returns[0], count);
    double confidence = (double)confidence_micro / (double)SCALE;
    double quantile = 1.0 - confidence;
    double position = (double)(count - 1) * quantile;
    usz lower = (usz)position;
    double fraction = position - (double)lower;
    double threshold = lower == count - 1 ? returns[count - 1]
        : returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction;
    return -threshold;
}
