module burrows_wheeler_transform;

const usz MAX_LENGTH = 256;

fn bool rotation_less(long* values, usz n, usz left, usz right) {
    for (usz offset = 0; offset < n; offset++) {
        long a = values[1 + (left + offset) % n];
        long b = values[1 + (right + offset) % n];
        if (a != b) return a < b;
    }
    return left < right;
}

fn long burrows_wheeler_transform(long* values, usz length, char* output, usz output_capacity)
        @export("burrows_wheeler_transform") {
    if (values == null || length < 2 || values[0] < 1 || (usz)values[0] > MAX_LENGTH) return -1;
    usz n = (usz)values[0];
    if (length != n + 1) return -1;
    for (usz i = 1; i < length; i++) if (values[i] < 0 || values[i] > 127) return -1;
    usz output_length = n + 4;
    if (output_capacity < output_length || output == null) return -2;

    usz[MAX_LENGTH] order;
    for (usz i = 0; i < n; i++) order[i] = i;
    for (usz i = 1; i < n; i++) {
        usz key = order[i];
        usz position = i;
        while (position > 0 && rotation_less(values, n, key, order[position - 1])) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = key;
    }

    usz primary_index = 0;
    for (usz row = 0; row < n; row++) if (order[row] == 0) primary_index = row;
    uint encoded_index = (uint)primary_index;
    for (usz byte = 0; byte < 4; byte++) output[byte] = (char)(encoded_index >> (8 * byte));
    for (usz row = 0; row < n; row++) output[4 + row] = (char)values[1 + (order[row] + n - 1) % n];
    return (long)output_length;
}
