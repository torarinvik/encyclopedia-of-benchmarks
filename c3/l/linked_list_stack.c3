module linked_list_stack;

const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 129;
const usz MAX_DEPTH = 64;
const usz MAX_OUTPUT_BYTES = 516;

struct StackNode { int value; int next; }

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long linked_list_stack(long* input, usz length, char* output, usz capacity)
        @export("linked_list_stack") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 64) return -1;

    usz operation_count = (usz)input[0];
    StackNode[64] nodes;
    int[128] records;
    usz node_count = 0, query_count = 0, cursor = 1;
    int top = -1, stack_size = 0;
    for (usz operation = 0; operation < operation_count; operation += 1) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor >= length) return -1;
            long value = input[cursor++];
            if (value < -2147483648 || value > 2147483647
                    || stack_size >= 64 || node_count >= MAX_DEPTH) return -1;
            nodes[node_count].value = (int)value;
            nodes[node_count].next = top;
            top = (int)node_count;
            node_count += 1;
            stack_size += 1;
        } else if (opcode == 1) {
            if (stack_size == 0 || top < 0) return -1;
            records[2 * query_count] = 1;
            records[2 * query_count + 1] = nodes[(usz)top].value;
            query_count += 1;
            top = nodes[(usz)top].next;
            stack_size -= 1;
        } else if (opcode == 2) {
            records[2 * query_count] = 2;
            records[2 * query_count + 1] = stack_size;
            query_count += 1;
        } else if (opcode == 3) {
            records[2 * query_count] = 3;
            records[2 * query_count + 1] = if (stack_size == 0) 1 else 0;
            query_count += 1;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    usz output_bytes = 4 + 8 * query_count;
    if (output == null || capacity < output_bytes) return -2;
    char[516] buffer;
    put_i32_le(&buffer[0], 0, (int)query_count);
    for (usz index = 0; index < 2 * query_count; index += 1)
        put_i32_le(&buffer[0], 4 + 4 * index, records[index]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = buffer[byte];
    return (long)output_bytes;
}
