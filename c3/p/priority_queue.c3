module priority_queue;

const usz MAX_OPS = 64;
const usz MAX_INPUT = 130;
const usz MAX_OUTPUT = 256;

fn long priority_queue(long* input, usz input_length, char* output, usz capacity)
    @export("priority_queue") {
    if (input == null || input_length == 0 || input_length > MAX_INPUT) return -1L;
    if (input[0] < 0 || input[0] > 64) return -1L;
    usz op_count = (usz)input[0];
    int[MAX_OPS] heap = zeroed;
    int[MAX_OPS] seen = zeroed;
    uint8[MAX_OUTPUT] staged = zeroed;
    usz heap_size = 0, seen_count = 0, offset = 1, output_size = 0;
    for (usz k = 0; k < op_count; k++) {
        if (offset >= input_length) return -1L;
        long op = input[offset++];
        if (op == 0) {
            if (offset >= input_length) return -1L;
            long raw = input[offset++];
            if (raw < -2147483648L || raw > 2147483647L) return -1L;
            int value = (int)raw;
            for (usz j = 0; j < seen_count; j++) if (seen[j] == value) return -1L;
            seen[seen_count++] = value;
            usz i = heap_size++;
            heap[i] = value;
            while (i != 0) {
                usz parent = (i - 1) / 2;
                if (heap[parent] <= heap[i]) break;
                int temp = heap[parent]; heap[parent] = heap[i]; heap[i] = temp;
                i = parent;
            }
        } else if (op == 1 || op == 2) {
            if (heap_size == 0) return -1L;
            uint32 bits = (uint32)heap[0];
            staged[output_size++] = (uint8)(bits & 255);
            staged[output_size++] = (uint8)((bits >> 8) & 255);
            staged[output_size++] = (uint8)((bits >> 16) & 255);
            staged[output_size++] = (uint8)((bits >> 24) & 255);
            if (op == 2) {
                heap[0] = heap[--heap_size];
                usz i = 0;
                while (i < heap_size) {
                    usz child = 2 * i + 1;
                    if (child >= heap_size) break;
                    if (child + 1 < heap_size && heap[child + 1] < heap[child]) child++;
                    if (heap[i] <= heap[child]) break;
                    int temp = heap[i]; heap[i] = heap[child]; heap[child] = temp;
                    i = child;
                }
            }
        } else return -1L;
    }
    if (offset != input_length) return -1L;
    if (output == null || capacity < output_size) return -2L;
    for (usz i = 0; i < output_size; i++) output[i] = (char)staged[i];
    return (long)output_size;
}
