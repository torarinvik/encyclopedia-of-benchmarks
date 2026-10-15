module jaccard_distance;

const double INVALID_RESULT = -1.0e300;

fn double jaccard_distance(long* values, usz length) @export("jaccard_distance") {
    if (values == null || length < 2) return INVALID_RESULT;
    long left_value = values[0];
    long right_value = values[1];
    if (left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64) return INVALID_RESULT;
    usz left_length = (usz)left_value;
    usz right_length = (usz)right_value;
    if (length != 2 + left_length + right_length) return INVALID_RESULT;
    for (usz i = 0; i < left_length; i++) if (values[2 + i] < 32 || values[2 + i] > 126) return INVALID_RESULT;
    for (usz j = 0; j < right_length; j++) if (values[2 + left_length + j] < 32 || values[2 + left_length + j] > 126) return INVALID_RESULT;

    usz intersection = 0;
    usz union_length = 0;
    for (usz i = 0; i < left_length; i++) {
        bool seen_before = false;
        for (usz k = 0; k < i; k++) if (values[2 + k] == values[2 + i]) { seen_before = true; break; }
        if (seen_before) continue;
        union_length++;
        for (usz j = 0; j < right_length; j++) if (values[2 + i] == values[2 + left_length + j]) { intersection++; break; }
    }
    for (usz j = 0; j < right_length; j++) {
        bool seen_before = false;
        for (usz k = 0; k < j; k++) if (values[2 + left_length + k] == values[2 + left_length + j]) { seen_before = true; break; }
        if (seen_before) continue;
        bool in_left = false;
        for (usz i = 0; i < left_length; i++) if (values[2 + i] == values[2 + left_length + j]) { in_left = true; break; }
        if (!in_left) union_length++;
    }
    if (union_length == 0) return 0.0;
    return 1.0 - (double)intersection / (double)union_length;
}
