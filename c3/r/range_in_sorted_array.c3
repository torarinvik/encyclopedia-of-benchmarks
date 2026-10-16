module range_in_sorted_array;

const long MAX_N = 512;
const long INT32_MIN_VALUE = -2147483648;
const long INT32_MAX_VALUE = 2147483647;

fn long find_bound(long* values, usz n, long key, bool find_left) {
    long left = 0;
    long right = (long)n - 1;
    while (left <= right) {
        long mid = left + (right - left) / 2;
        if (values[mid] > key) {
            right = mid - 1;
        } else if (values[mid] < key) {
            left = mid + 1;
        } else if (find_left) {
            if (mid == 0 || values[mid - 1] != key) {
                return mid;
            }
            right = mid - 1;
        } else {
            if ((usz)mid == n - 1 || values[mid + 1] != key) {
                return mid;
            }
            left = mid + 1;
        }
    }
    return -1;
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz i = 0; i < 4; i++) output[offset + i] = (char)(bits >> (8 * i));
}

fn long range_in_sorted_array(long* input, usz length, char* output, usz output_capacity)
    @export("range_in_sorted_array") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > MAX_N || length != (usz)input[0] + 2) return -1;
    usz n = (usz)input[0];
    long key = input[n + 1];
    if (key < INT32_MIN_VALUE || key > INT32_MAX_VALUE) return -1;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < INT32_MIN_VALUE || input[i + 1] > INT32_MAX_VALUE) return -1;
        if (i > 0 && input[i] > input[i + 1]) return -1;
    }
    long first = find_bound(input + 1, n, key, true);
    long last = find_bound(input + 1, n, key, false);
    if (output == null || output_capacity < 8) return -2;
    put_i32_le(output, 0, (int)first);
    put_i32_le(output, 4, (int)last);
    return 8;
}
