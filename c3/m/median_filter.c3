module median_filter;

const usz MAX_WINDOW = 16;
const usz MAX_SAMPLES = 64;

fn usz lower_bound(double* sorted, usz size, double value) {
    usz low = 0, high = size;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (sorted[middle] < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

fn long median_filter(double* input, usz length, double* output, usz capacity) @export("median_filter") {
    if (input == null || length < 2 || length > 66) return -1;
    double window_value = input[0], count_value = input[1];
    if (window_value != window_value || window_value < 1.0 || window_value > 16.0 || window_value != (double)(long)window_value ||
        count_value != count_value || count_value < 0.0 || count_value > 64.0 || count_value != (double)(long)count_value) return -1;
    usz window = (usz)(long)window_value;
    usz count = (usz)(long)count_value;
    if (length != 2 + count) return -1;
    double[MAX_SAMPLES] samples = {0};
    for (usz index = 0; index < count; index++) {
        double value = input[2 + index];
        if (value != value || value < -1000000.0 || value > 1000000.0) return -1;
        samples[index] = value;
    }
    if (output == null || capacity < count) return -2;

    double[MAX_WINDOW] arrival = {0}, sorted = {0};
    double[MAX_SAMPLES] result = {0};
    usz size = 0, oldest = 0;
    for (usz index = 0; index < count; index++) {
        double value = samples[index];
        if (size == window) {
            usz position = lower_bound(&sorted, size, arrival[oldest]);
            for (usz shift = position + 1; shift < size; shift++) sorted[shift - 1] = sorted[shift];
            size--;
        }
        usz position = lower_bound(&sorted, size, value);
        for (usz shift = size; shift > position; shift--) sorted[shift] = sorted[shift - 1];
        sorted[position] = value;
        arrival[oldest] = value;
        oldest = (oldest + 1) % window;
        size++;
        usz middle = size / 2;
        result[index] = size % 2 != 0 ? sorted[middle] : 0.5 * (sorted[middle - 1] + sorted[middle]);
    }
    for (usz index = 0; index < count; index++) output[index] = result[index];
    return (long)count;
}
