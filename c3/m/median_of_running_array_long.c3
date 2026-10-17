module median_of_running_array_long;

const usz MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = 66;
const long MIN_SAMPLE = -4611686018427387904;
const long MAX_SAMPLE = 4611686018427387903;

void store_i64_le(char* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}
void push_max(long* heap, usz* count, long value) {
    usz position = (*count)++;
    while (position > 0 && heap[(position - 1) / 2] < value) { usz parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
long pop_max(long* heap, usz* count) {
    long result = heap[0], value = heap[--(*count)]; if (*count == 0) return result;
    usz position = 0;
    while (2 * position + 1 < *count) { usz child = 2 * position + 1; if (child + 1 < *count && heap[child + 1] > heap[child]) child++; if (heap[child] <= value) break; heap[position] = heap[child]; position = child; }
    heap[position] = value; return result;
}
void push_min(long* heap, usz* count, long value) {
    usz position = (*count)++;
    while (position > 0 && heap[(position - 1) / 2] > value) { usz parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
long pop_min(long* heap, usz* count) {
    long result = heap[0], value = heap[--(*count)]; if (*count == 0) return result;
    usz position = 0;
    while (2 * position + 1 < *count) { usz child = 2 * position + 1; if (child + 1 < *count && heap[child + 1] < heap[child]) child++; if (heap[child] >= value) break; heap[position] = heap[child]; position = child; }
    heap[position] = value; return result;
}

fn long median_of_running_array_long(long* input, usz length, char* output, usz capacity)
    @export("median_of_running_array_long") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > 64 || length != 1 + (usz)count_value) return -1;
    usz count = (usz)count_value;
    long[MAX_COUNT] lower = zeroed, upper = zeroed, medians = zeroed;
    usz lower_count = 0, upper_count = 0;
    for (usz i = 0; i < count; i++) {
        long sample = input[i + 1];
        if (sample < MIN_SAMPLE || sample > MAX_SAMPLE) return -1;
        if (upper_count > 0 && sample < upper[0]) push_max(&lower[0], &lower_count, sample);
        else push_min(&upper[0], &upper_count, sample);
        if (lower_count > upper_count + 1) push_min(&upper[0], &upper_count, pop_max(&lower[0], &lower_count));
        else if (upper_count > lower_count + 1) push_max(&lower[0], &lower_count, pop_min(&upper[0], &upper_count));
        if (lower_count > upper_count) medians[i] = lower[0];
        else if (upper_count > lower_count) medians[i] = upper[0];
        else medians[i] = (lower[0] + upper[0]) / 2;
    }
    usz output_bytes = count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < count; i++) store_i64_le(output, i * 8, medians[i]);
    return (long)output_bytes;
}
