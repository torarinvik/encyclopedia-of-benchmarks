module smoothsort;

const int MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = 66;

void sift(long* values, int root, int order, int* leonardo) {
    while (order > 1) {
        int right = root - 1, left = root - 1 - leonardo[order - 2];
        if (!(values[left] < values[right]) && values[root] < values[left]) {
            long temporary = values[root]; values[root] = values[left]; values[left] = temporary;
            root = left; --order;
        } else if (values[left] < values[right] && values[root] < values[right]) {
            long temporary = values[root]; values[root] = values[right]; values[right] = temporary;
            root = right; order -= 2;
        } else break;
    }
}
void trinkle(long* values, int position, int* orders, int index, int* leonardo) {
    while (index > 0) {
        int previous = position - leonardo[orders[index]];
        if (!(values[position] < values[previous])) break;
        if (orders[index] > 1) {
            int right = position - 1, left = position - 1 - leonardo[orders[index] - 2];
            if (!(values[right] < values[previous]) || !(values[left] < values[previous])) break;
        }
        long temporary = values[position]; values[position] = values[previous]; values[previous] = temporary;
        position = previous; --index;
    }
    sift(values, position, orders[index], leonardo);
}
void smooth_sort(long* values, int count) {
    if (count < 2) return;
    int[16] leonardo = zeroed; leonardo[0] = 1; leonardo[1] = 1;
    for (int i = 2; i < 16; ++i) leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1;
    int[MAX_COUNT] orders = zeroed; int heap_count = 0;
    for (int position = 0; position < count; ++position) {
        if (heap_count >= 2 && orders[heap_count - 2] == orders[heap_count - 1] + 1) {
            --heap_count; ++orders[heap_count - 1];
        } else if (heap_count > 0 && orders[heap_count - 1] == 1) orders[heap_count++] = 0;
        else orders[heap_count++] = 1;
        trinkle(values, position, &orders[0], heap_count - 1, &leonardo[0]);
    }
    for (int position = count - 1; position >= 0; --position) {
        int order = orders[--heap_count];
        if (order > 1) {
            int right_order = order - 2, left_order = order - 1;
            int right_position = position - 1, left_position = position - 1 - leonardo[right_order];
            orders[heap_count++] = left_order; trinkle(values, left_position, &orders[0], heap_count - 1, &leonardo[0]);
            orders[heap_count++] = right_order; trinkle(values, right_position, &orders[0], heap_count - 1, &leonardo[0]);
        }
    }
}
void store_i64(char* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; ++byte) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long smoothsort(long* input, usz length, char* output, usz capacity) @export("smoothsort") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_COUNT) return -1;
    int count = (int)input[0];
    if (length != 1 + (usz)count || length > (usz)(MAX_COUNT + 1)) return -1;
    long[MAX_COUNT] values = zeroed;
    for (int i = 0; i < count; ++i) values[i] = input[i + 1];
    smooth_sort(&values[0], count);
    usz output_bytes = (usz)count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (int i = 0; i < count; ++i) store_i64(output, (usz)i * 8, values[i]);
    return (long)output_bytes;
}
