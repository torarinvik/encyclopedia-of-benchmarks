module hampel_filter;

const usz MAX_N = 128;
const usz WINDOW = 3;

fn usz insert_sorted(double* values, usz size, double value) {
    usz position = 0;
    while (position < size && values[position] < value) {
        position++;
    }
    for (usz index = size; index > position; index--) {
        values[index] = values[index - 1];
    }
    values[position] = value;
    return size + 1;
}

fn usz remove_sorted(double* values, usz size, double value) {
    usz position = 0;
    while (position < size && values[position] != value) {
        position++;
    }
    if (position == size) {
        return size;
    }
    for (usz index = position + 1; index < size; index++) {
        values[index - 1] = values[index];
    }
    return size - 1;
}

fn double median(double* values, usz size) {
    usz middle = size / 2;
    if (size % 2 != 0) {
        return values[middle];
    }
    return 0.5 * (values[middle - 1] + values[middle]);
}

fn double median_absolute_deviation(double* sorted, usz size, double center) {
    double[WINDOW] deviations;
    usz deviation_count = 0;
    for (usz index = 0; index < size; index++) {
        double difference = sorted[index] - center;
        if (difference < 0.0) {
            difference = -difference;
        }
        deviation_count = insert_sorted(&deviations[0], deviation_count, difference);
    }
    return median(&deviations[0], deviation_count);
}

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long hampel_filter(long* input, usz length, char* output, usz capacity) @export("hampel_filter") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > (long)MAX_N || length != (usz)input[0] + 1) {
        return -1;
    }
    usz count = (usz)input[0];
    for (usz index = 0; index < count; index++) {
        if (input[index + 1] < -1000 || input[index + 1] > 1000) {
            return -1;
        }
    }
    if (capacity < count * 8 || (count > 0 && output == null)) {
        return -2;
    }

    double[WINDOW] arrival;
    double[WINDOW] sorted;
    usz size = 0;
    usz oldest = 0;
    for (usz index = 0; index < count; index++) {
        double value = (double)input[index + 1];
        if (size == WINDOW) {
            size = remove_sorted(&sorted[0], size, arrival[oldest]);
        }
        size = insert_sorted(&sorted[0], size, value);
        arrival[oldest] = value;
        oldest = (oldest + 1) % WINDOW;

        double center = median(&sorted[0], size);
        double deviation = median_absolute_deviation(&sorted[0], size, center);
        double distance = value >= center ? value - center : center - value;
        double filtered = distance > 3.0 * 1.4826 * deviation ? center : value;
        put_i64_le((long)filtered, output, index * 8);
    }
    return (long)(count * 8);
}
