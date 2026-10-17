module priority_queues;

const long MAX_CAPACITY = 128;
const long MAX_OPERATIONS = 256;
const usz MAX_INPUT_VALUES = 515;
const usz MAX_OUTPUT_BYTES = 4096;

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long priority_queues(long* input, usz length, char* output, usz output_capacity)
    @export("priority_queues") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_CAPACITY ||
        input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;

    usz capacity = (usz)input[0];
    usz operation_count = (usz)input[1];
    if (length != 2 + 2 * operation_count) return -1;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[2 + 2 * operation];
        long argument = input[3 + 2 * operation];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < -2147483648 || argument > 2147483647) return -1;
        } else if (argument != 0) {
            return -1;
        }
    }

    if (operation_count == 0) return 0;
    usz needed = operation_count * 16;
    if (needed > MAX_OUTPUT_BYTES || output == null || output_capacity < needed) return -2;

    int[MAX_CAPACITY + 1] heap = zeroed;
    usz size = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[2 + 2 * operation];
        long argument = input[3 + 2 * operation];
        long status = 0;
        long value = 0;

        if (opcode == 0) {
            if (size == capacity) {
                status = 1;
            } else {
                size++;
                heap[size] = (int)argument;
                usz index = size;
                while (index > 1 && heap[index / 2] < heap[index]) {
                    int temporary = heap[index / 2];
                    heap[index / 2] = heap[index];
                    heap[index] = temporary;
                    index /= 2;
                }
            }
        } else if (opcode == 1) {
            if (size == 0) {
                status = 2;
            } else {
                value = (long)heap[1];
                heap[1] = heap[size];
                heap[size] = 0;
                size--;
                usz index = 1;
                while (index * 2 <= size) {
                    usz child = index * 2;
                    if (child < size && heap[child + 1] > heap[child]) child++;
                    if (heap[index] >= heap[child]) break;
                    int temporary = heap[index];
                    heap[index] = heap[child];
                    heap[child] = temporary;
                    index = child;
                }
            }
        } else if (opcode == 2) {
            value = size == 0 ? 0 : (long)heap[1];
        } else if (opcode == 3) {
            value = size == 0 ? 1 : 0;
        } else if (opcode == 4) {
            value = size == capacity ? 1 : 0;
        } else {
            value = (long)size;
        }

        store_i64_le(status, output, operation * 16);
        store_i64_le(value, output, operation * 16 + 8);
    }
    return (long)needed;
}
