module sort_stack;

const usz MAX_ITEMS = 64;

fn void insert_sorted(long* stack, usz* size, long value) {
    if (*size == 0 || value > stack[*size - 1]) {
        stack[*size] = value;
        *size += 1;
        return;
    }
    *size -= 1;
    long top = stack[*size];
    insert_sorted(stack, size, value);
    stack[*size] = top;
    *size += 1;
}

fn void sort_recursively(long* stack, usz* size) {
    if (*size == 0) return;
    *size -= 1;
    long top = stack[*size];
    sort_recursively(stack, size);
    insert_sorted(stack, size, top);
}

long sort_stack(long* input, usz length, char* output, usz output_capacity)
        @export("sort_stack") {
    if (input == null || length < 1 || length > 65) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_ITEMS || length != 1 + (usz)input[0]) return -1;
    usz count = (usz)input[0];
    long stack[64];
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] < -2147483648L || input[i + 1] > 2147483647L) return -1;
        stack[i] = input[i + 1];
    }
    usz size = count;
    sort_recursively(stack, &size);
    usz bytes = size * 4;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < size; i++) {
        ulong bits = (ulong)stack[i];
        for (usz b = 0; b < 4; b++) output[4*i+b] = (char)((bits >> (8*b)) & 255);
    }
    return (long)bytes;
}
