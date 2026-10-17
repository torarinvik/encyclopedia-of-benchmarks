module scan_scheduling;

const int MAX_REQUESTS = 64;
const int MAX_OUTPUT_VALUES = 65;

fn void sort_ascending(int* values, usz count) {
    for (usz i = 1; i < count; i += 1) {
        int value = values[i];
        usz position = i;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long scan_scheduling(int* input, usz length, char* output, usz capacity)
    @export("scan_scheduling") {
    if (input == null || length < 4 || length > 68) return -1;
    int disk_size = input[0], head = input[1], direction = input[2], request_count = input[3];
    if (disk_size < 1 || disk_size > 256 || head < 0 || head >= disk_size ||
        (direction != 0 && direction != 1) || request_count < 0 || request_count > MAX_REQUESTS ||
        length != 4 + (usz)request_count) return -1;

    int[MAX_REQUESTS] left;
    int[MAX_REQUESTS] right;
    usz left_count = 0, right_count = 0;
    for (usz i = 0; i < (usz)request_count; i += 1) {
        int request = input[4 + i];
        if (request < 0 || request >= disk_size) return -1;
        if (request < head) {
            left[left_count] = request;
            left_count += 1;
        } else {
            right[right_count] = request;
            right_count += 1;
        }
    }
    sort_ascending(&left[0], left_count);
    sort_ascending(&right[0], right_count);

    int[MAX_OUTPUT_VALUES] ordered;
    usz count = 0;
    if (request_count > 0) {
        if (direction == 1) {
            for (usz i = 0; i < right_count; i += 1) { ordered[count] = right[i]; count += 1; }
            ordered[count] = disk_size - 1;
            count += 1;
            for (usz i = left_count; i > 0; i -= 1) { ordered[count] = left[i - 1]; count += 1; }
        } else {
            for (usz i = left_count; i > 0; i -= 1) { ordered[count] = left[i - 1]; count += 1; }
            ordered[count] = 0;
            count += 1;
            for (usz i = 0; i < right_count; i += 1) { ordered[count] = right[i]; count += 1; }
        }
    }
    usz bytes = count * 4;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < count; i += 1) put_i32_le(output, i * 4, ordered[i]);
    return (long)bytes;
}
