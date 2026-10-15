module simplified_wiggle_sort;
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

fn long simplified_wiggle_sort(long* input, usz length, char* output, usz output_capacity)
    @export("simplified_wiggle_sort") {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == null)) return -1;
    long[MAX_ARRAY_LENGTH] values;
    long[MAX_ARRAY_LENGTH] ordered;
    for (usz i = 0; i < length; i++) {
        if (input[i] < -2147483648 || input[i] > 2147483647) return -1;
        values[i] = input[i];
    }
    usz bytes = length * 4;
    if (output_capacity < bytes || (bytes != 0 && output == null)) return -2;
    if (length == 0) return 0;

    long median = select_kth(&values[0], length, length / 2);
    usz smaller = 0;
    long greater = (long)(length - 1 - (length % 2));
    for (usz i = 0; i < length; i++) {
        if (values[i] > median) {
            ordered[(usz)greater] = values[i];
            greater -= 2;
        } else if (smaller < length) {
            ordered[smaller] = values[i];
            smaller += 2;
        } else {
            ordered[(usz)greater] = values[i];
            greater -= 2;
        }
    }
    for (usz i = 0; i < length; i++) {
        uint bits = (uint)(int)ordered[i];
        for (usz byte = 0; byte < 4; byte++) {
            output[i * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)length;
}
