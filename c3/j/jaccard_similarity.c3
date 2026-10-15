module jaccard_similarity;

const double INVALID_RESULT = -1.0e300;

fn double jaccard_similarity(long* values, usz length) @export("jaccard_similarity") {
    if (values == null || length < 2) return INVALID_RESULT;
    long left_value = values[0];
    long right_value = values[1];
    if (left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64 ||
        (left_value == 0 && right_value == 0)) return INVALID_RESULT;
    usz left_length = (usz)left_value;
    usz right_length = (usz)right_value;
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    for (usz i = 0; i < left_length; i++) {
        long value = values[2 + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        for (usz before = 0; before < i; before++) {
            if (values[2 + before] == value) return INVALID_RESULT;
        }
    }
    for (usz i = 0; i < right_length; i++) {
        long value = values[2 + left_length + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        for (usz before = 0; before < i; before++) {
            if (values[2 + left_length + before] == value) return INVALID_RESULT;
        }
    }

    usz intersection = 0;
    for (usz i = 0; i < left_length; i++) {
        for (usz j = 0; j < right_length; j++) {
            if (values[2 + i] == values[2 + left_length + j]) { intersection++; break; }
        }
    }
    usz union_length = left_length + right_length - intersection;
    return (double)intersection / (double)union_length;
}
