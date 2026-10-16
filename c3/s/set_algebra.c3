module set_algebra;

const usz MAX_SET_SIZE = 64;
const usz MAX_RESULT_SIZE = 2 * MAX_SET_SIZE;
const usz MAX_INPUT_LENGTH = 4 + 2 * MAX_SET_SIZE;

fn bool contains(long* values, usz count, long value) {
    for (usz i = 0; i < count; i++) if (values[i] == value) return true;
    return false;
}
fn bool is_subset(long* left, usz left_count, long* right, usz right_count) {
    if (left_count > right_count) return false;
    for (usz i = 0; i < left_count; i++) if (!contains(right, right_count, left[i])) return false;
    return true;
}
fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long set_algebra(long* input, usz length, char* output, usz capacity) @export("set_algebra") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long operation = input[0], left_raw = input[1], right_raw = input[2], query_key = input[3];
    if (operation < 0 || operation > 8 || left_raw < 0 || left_raw > (long)MAX_SET_SIZE || right_raw < 0 || right_raw > (long)MAX_SET_SIZE || query_key < -1000000 || query_key > 1000000) return -1;
    usz left_length = (usz)left_raw, right_length = (usz)right_raw;
    if (length != 4 + left_length + right_length) return -1;

    long[MAX_SET_SIZE] left, right;
    long[MAX_RESULT_SIZE] result;
    usz left_count = 0, right_count = 0, result_count = 0;
    for (usz i = 0; i < left_length; i++) {
        long value = input[4 + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (!contains(&left[0], left_count, value)) left[left_count++] = value;
    }
    for (usz i = 0; i < right_length; i++) {
        long value = input[4 + left_length + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (!contains(&right[0], right_count, value)) right[right_count++] = value;
    }

    if (operation == 0) { result[0] = contains(&left[0], left_count, query_key) ? 1 : 0; result_count = 1; }
    else if (operation == 1) { result[0] = is_subset(&left[0], left_count, &right[0], right_count) ? 1 : 0; result_count = 1; }
    else if (operation == 2) { result[0] = left_count < right_count && is_subset(&left[0], left_count, &right[0], right_count) ? 1 : 0; result_count = 1; }
    else if (operation == 3) { result[0] = is_subset(&right[0], right_count, &left[0], left_count) ? 1 : 0; result_count = 1; }
    else if (operation == 4) { result[0] = right_count < left_count && is_subset(&right[0], right_count, &left[0], left_count) ? 1 : 0; result_count = 1; }
    else if (operation == 5) {
        for (usz i = 0; i < left_count; i++) result[result_count++] = left[i];
        for (usz i = 0; i < right_count; i++) if (!contains(&left[0], left_count, right[i])) result[result_count++] = right[i];
    } else if (operation == 6) {
        for (usz i = 0; i < left_count; i++) if (contains(&right[0], right_count, left[i])) result[result_count++] = left[i];
    } else if (operation == 7) {
        for (usz i = 0; i < left_count; i++) if (!contains(&right[0], right_count, left[i])) result[result_count++] = left[i];
    } else {
        for (usz i = 0; i < left_count; i++) if (!contains(&right[0], right_count, left[i])) result[result_count++] = left[i];
        for (usz i = 0; i < right_count; i++) if (!contains(&left[0], left_count, right[i])) result[result_count++] = right[i];
    }
    for (usz i = 1; i < result_count; i++) {
        long value = result[i];
        usz j = i;
        while (j > 0 && result[j - 1] > value) { result[j] = result[j - 1]; j--; }
        result[j] = value;
    }

    usz output_bytes = result_count * 8;
    if (capacity < output_bytes || (output_bytes > 0 && output == null)) return -2;
    for (usz i = 0; i < result_count; i++) put_i64_le(output, i * 8, result[i]);
    return (long)output_bytes;
}
