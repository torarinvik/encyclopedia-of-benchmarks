module wiggle_sort_strict;
const usz MAX_ARRAY_LENGTH = 4096;

fn long select_kth(long* values, usz count, usz target) {
    long low = 0;
    long high = (long)count - 1;
    while (low < high) {
        long left = low;
        long right = high;
        long pivot = values[(usz)((left + right + 1) / 2)];
        while (left <= right) {
            while (left <= right && values[(usz)left] < pivot) left++;
            while (left <= right && values[(usz)right] > pivot) right--;
            if (left <= right) {
                long temporary = values[(usz)left];
                values[(usz)left] = values[(usz)right];
                values[(usz)right] = temporary;
                left++;
                right--;
            }
        }
        if ((long)target <= right) { high = right; }
        else if ((long)target >= left) { low = left; }
        else { break; }
    }
    return values[target];
}

fn long wiggle_sort_strict(long* input, usz length, char* output, usz output_capacity)
    @export("wiggle_sort_strict") {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == null)) return -1;
    long[MAX_ARRAY_LENGTH] values;

    for (usz i = 0; i < length; i++) {
        if (input[i] < -2147483648 || input[i] > 2147483647) return -1;
        values[i] = input[i];
    }
    usz bytes = length * 4;
    if (output_capacity < bytes || (bytes != 0 && output == null)) return -2;
    if (length == 0) return 0;

    long median = select_kth(&values[0], length, length / 2);
    usz median_count = 0;
    long smallest_value = values[0];
    for (usz i = 0; i < length; i++) {
        if (values[i] == median) median_count++;
        if (values[i] < smallest_value) smallest_value = values[i];
    }
    usz maximum_medians = (length + 1) / 2;
    if (median_count > maximum_medians
        || (length % 2 == 1 && median_count == maximum_medians && smallest_value != median)) return -1;

    long i = 0;
    long j = 0;
    long k = (long)length - 1;
    long modulus = (long)length + 1 - (long)(length % 2);
    while (j <= k) {
        usz mapped_j = (usz)((2 * j + 1) % modulus);
        if (values[mapped_j] > median) {
            usz mapped_i = (usz)((2 * i + 1) % modulus);
            long temporary = values[mapped_j];
            values[mapped_j] = values[mapped_i];
            values[mapped_i] = temporary;
            i++;
            j++;
        } else if (values[mapped_j] < median) {
            usz mapped_k = (usz)((2 * k + 1) % modulus);
            long temporary = values[mapped_j];
            values[mapped_j] = values[mapped_k];
            values[mapped_k] = temporary;
            k--;
        } else {
            j++;
        }
    }
    for (usz out_i = 0; out_i < length; out_i++) {
        uint bits = (uint)(int)values[out_i];
        for (usz byte = 0; byte < 4; byte++) {
            output[out_i * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)length;
}
