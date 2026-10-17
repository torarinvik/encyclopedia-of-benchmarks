module median_of_running_array_byte;

void push_max(int* heap, usz* count, int value) { usz i = count[0]++; while (i > 0 && heap[(i-1)/2] < value) { heap[i] = heap[(i-1)/2]; i = (i-1)/2; } heap[i] = value; }
int pop_max(int* heap, usz* count) { int result = heap[0], value = heap[--count[0]]; if (count[0] == 0) return result; usz i = 0; while (2*i+1 < count[0]) { usz child = 2*i+1; if (child+1 < count[0] && heap[child+1] > heap[child]) child++; if (heap[child] <= value) break; heap[i] = heap[child]; i = child; } heap[i] = value; return result; }
void push_min(int* heap, usz* count, int value) { usz i = count[0]++; while (i > 0 && heap[(i-1)/2] > value) { heap[i] = heap[(i-1)/2]; i = (i-1)/2; } heap[i] = value; }
int pop_min(int* heap, usz* count) { int result = heap[0], value = heap[--count[0]]; if (count[0] == 0) return result; usz i = 0; while (2*i+1 < count[0]) { usz child = 2*i+1; if (child+1 < count[0] && heap[child+1] < heap[child]) child++; if (heap[child] >= value) break; heap[i] = heap[child]; i = child; } heap[i] = value; return result; }

fn long median_of_running_array_byte(int* input, usz length, char* output, usz capacity)
    @export("median_of_running_array_byte") {
    if (input == null || length < 1 || length > 66) return -1;
    int count = input[0];
    if (count < 1 || count > 64 || length != 1 + (usz)count) return -1;
    int[64] lower = zeroed, upper = zeroed;
    char[64] medians = zeroed;
    usz lower_count = 0, upper_count = 0;
    for (usz i = 0; i < (usz)count; i += 1) {
        int sample = input[i + 1];
        if (sample < -128 || sample > 127) return -1;
        if (upper_count > 0 && sample < upper[0]) push_max(&lower[0], &lower_count, sample);
        else push_min(&upper[0], &upper_count, sample);
        if (lower_count > upper_count + 1) push_min(&upper[0], &upper_count, pop_max(&lower[0], &lower_count));
        else if (upper_count > lower_count + 1) push_max(&lower[0], &lower_count, pop_min(&upper[0], &upper_count));
        int median;
        if (lower_count > upper_count) median = lower[0];
        else if (upper_count > lower_count) median = upper[0];
        else {
            int sum = lower[0] + upper[0];
            median = sum < 0 ? -((-sum) / 2) : sum / 2;
        }
        medians[i] = (char)(median & 255);
    }
    if (output == null || capacity < (usz)count) return -2;
    for (usz i = 0; i < (usz)count; i += 1) output[i] = medians[i];
    return count;
}
