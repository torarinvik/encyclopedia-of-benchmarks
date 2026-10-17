module merge_sort_no_extra_space;

const usz MAX_LENGTH = 256;

fn int read_i32_le(char* buffer, usz index) {
    usz offset = index * 4;
    uint bits = ((uint)buffer[offset] & 255)
        | (((uint)buffer[offset + 1] & 255) << 8)
        | (((uint)buffer[offset + 2] & 255) << 16)
        | (((uint)buffer[offset + 3] & 255) << 24);
    return (int)bits;
}

fn void write_i32_le(char* buffer, usz index, int value) {
    uint bits = (uint)value;
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        buffer[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void merge(char* buffer, usz start, usz middle, usz end, int max_element) {
    usz i = start, j = middle + 1, k = start;
    while (i <= middle && j <= end) {
        int left = read_i32_le(buffer, i) % max_element;
        int right = read_i32_le(buffer, j) % max_element;
        int current = read_i32_le(buffer, k);
        if (left <= right) {
            write_i32_le(buffer, k, current + left * max_element);
            i += 1;
        } else {
            write_i32_le(buffer, k, current + right * max_element);
            j += 1;
        }
        k += 1;
    }
    while (i <= middle) {
        int current = read_i32_le(buffer, k);
        int next = read_i32_le(buffer, i) % max_element;
        write_i32_le(buffer, k, current + next * max_element);
        i += 1;
        k += 1;
    }
    while (j <= end) {
        int current = read_i32_le(buffer, k);
        int next = read_i32_le(buffer, j) % max_element;
        write_i32_le(buffer, k, current + next * max_element);
        j += 1;
        k += 1;
    }
    for (usz index = start; index <= end; index += 1)
        write_i32_le(buffer, index, read_i32_le(buffer, index) / max_element);
}

fn void merge_sort(char* buffer, usz start, usz end, int max_element) {
    if (start >= end) return;
    usz middle = start + (end - start) / 2;
    merge_sort(buffer, start, middle, max_element);
    merge_sort(buffer, middle + 1, end, max_element);
    merge(buffer, start, middle, end, max_element);
}

long merge_sort_no_extra_space(int* values, usz length, char* output, usz output_capacity) @export("merge_sort_no_extra_space") {
    if (values == null || length > MAX_LENGTH) return -1;
    int max_value = 0;
    for (usz index = 0; index < length; index += 1) {
        if (values[index] < 0 || values[index] > 32767) return -1;
        if (values[index] > max_value) max_value = values[index];
    }
    usz output_bytes = length * 4;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < length; index += 1) write_i32_le(output, index, values[index]);
    if (length > 1) merge_sort(output, 0, length - 1, max_value + 1);
    return (long)output_bytes;
}
