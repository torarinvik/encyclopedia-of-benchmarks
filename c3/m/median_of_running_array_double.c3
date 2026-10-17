module median_of_running_array_double;

const usz MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = 66;

bool less_double(double left, double right) {
    if (left < right) return true;
    if (left == 0.0 && right == 0.0)
        return ((@bitcast(ulong, left) >> 63) != 0) && ((@bitcast(ulong, right) >> 63) == 0);
    return false;
}
void push_max(double* heap, usz* count, double value) {
    usz position = (*count)++;
    while (position > 0 && less_double(heap[(position - 1) / 2], value)) {
        usz parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
double pop_max(double* heap, usz* count) {
    double result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    usz position = 0;
    while (2 * position + 1 < *count) {
        usz child = 2 * position + 1;
        if (child + 1 < *count && less_double(heap[child], heap[child + 1])) child++;
        if (!less_double(value, heap[child])) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}
void push_min(double* heap, usz* count, double value) {
    usz position = (*count)++;
    while (position > 0 && less_double(value, heap[(position - 1) / 2])) {
        usz parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
double pop_min(double* heap, usz* count) {
    double result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    usz position = 0;
    while (2 * position + 1 < *count) {
        usz child = 2 * position + 1;
        if (child + 1 < *count && less_double(heap[child + 1], heap[child])) child++;
        if (!less_double(heap[child], value)) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}

fn long median_of_running_array_double(double* input, usz length, double* output, usz capacity)
    @export("median_of_running_array_double") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    double count_value = input[0];
    if (count_value != count_value || count_value < 1.0 || count_value > 64.0 || (double)(usz)count_value != count_value || length != 1 + (usz)count_value) return -1;
    usz count = (usz)count_value;
    double[MAX_COUNT] lower = zeroed, upper = zeroed, medians = zeroed;
    usz lower_count = 0, upper_count = 0;
    for (usz i = 0; i < count; i++) {
        double sample = input[i + 1];
        if (sample != sample || sample < -1000000.0 || sample > 1000000.0) return -1;
        if (upper_count > 0 && less_double(sample, upper[0])) push_max(&lower[0], &lower_count, sample);
        else push_min(&upper[0], &upper_count, sample);
        if (lower_count > upper_count + 1) push_min(&upper[0], &upper_count, pop_max(&lower[0], &lower_count));
        else if (upper_count > lower_count + 1) push_max(&lower[0], &lower_count, pop_min(&upper[0], &upper_count));
        if (lower_count > upper_count) medians[i] = lower[0];
        else if (upper_count > lower_count) medians[i] = upper[0];
        else medians[i] = (lower[0] + upper[0]) / 2.0;
    }
    if (output == null || capacity < count) return -2;
    for (usz i = 0; i < count; i++) output[i] = medians[i];
    return (long)count;
}
