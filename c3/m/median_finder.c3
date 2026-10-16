module median_finder;

const long MAX_COUNT = 64;
const long VALUE_LIMIT = 1000000;

fn void heap_push(long[32]* heap, usz* size, bool is_max, long value) {
    usz index = *size;
    (*size)++;
    heap[index] = value;
    while (index > 0) {
        usz parent = (index - 1) / 2;
        bool ordered = is_max ? heap[parent] >= heap[index] : heap[parent] <= heap[index];
        if (ordered) break;
        long temporary = heap[parent]; heap[parent] = heap[index]; heap[index] = temporary;
        index = parent;
    }
}

fn long heap_pop(long[32]* heap, usz* size, bool is_max) {
    long result = heap[0];
    (*size)--;
    heap[0] = heap[*size];
    usz index = 0;
    while (true) {
        usz left = 2 * index + 1, right = left + 1, best = index;
        if (left < *size && (is_max ? heap[left] > heap[best] : heap[left] < heap[best])) best = left;
        if (right < *size && (is_max ? heap[right] > heap[best] : heap[right] < heap[best])) best = right;
        if (best == index) break;
        long temporary = heap[index]; heap[index] = heap[best]; heap[best] = temporary;
        index = best;
    }
    return result;
}

fn void write_f64(char* output, usz position, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)(bits >> (8 * byte));
    }
}

fn long median_finder(long* input, usz length, char* output, usz output_capacity)
    @export("median_finder") {
    if (input == null || length < 2 || length > 65) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > MAX_COUNT || length != (usz)count_value + 1) return -1;
    usz count = (usz)count_value;
    for (usz index = 0; index < count; index++)
        if (input[index + 1] < -VALUE_LIMIT || input[index + 1] > VALUE_LIMIT) return -1;
    usz required = count * 8;
    if (output == null || output_capacity < required) return -2;

    long[32] lower;
    long[32] upper;
    usz lower_size = 0;
    usz upper_size = 0;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (lower_size == 32 && lower_size > upper_size && value <= lower[0]) {
            heap_push(&upper, &upper_size, false, heap_pop(&lower, &lower_size, true));
            heap_push(&lower, &lower_size, true, value);
        } else {
            if (lower_size == 0 || value <= lower[0]) heap_push(&lower, &lower_size, true, value);
            else heap_push(&upper, &upper_size, false, value);
            if (lower_size > upper_size + 1)
                heap_push(&upper, &upper_size, false, heap_pop(&lower, &lower_size, true));
            else if (upper_size > lower_size)
                heap_push(&lower, &lower_size, true, heap_pop(&upper, &upper_size, false));
        }
        double median = lower_size == upper_size
            ? ((double)lower[0] + (double)upper[0]) / 2.0
            : (double)lower[0];
        write_f64(output, index * 8, median);
    }
    return (long)required;
}
