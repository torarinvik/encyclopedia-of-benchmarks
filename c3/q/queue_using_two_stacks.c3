module queue_using_two_stacks;

// Amortized FIFO queue implemented with an input and an output stack.
fn long queue_using_two_stacks_benchmark(long* values, usz length) @export("queue_using_two_stacks_benchmark")
{
    if (length > 1024 || length % 2 != 0) return -1;
    usz operation_count = length / 2;
    long[256] in_stack;
    long[256] out_stack;
    usz in_count = 0;
    usz out_count = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[2 * operation];
        long payload = values[2 * operation + 1];
        long observed = 0;
        bool returns_value = true;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || in_count + out_count == 256) return -1;
            in_stack[in_count++] = payload;
            returns_value = false;
        } else if (opcode == 1 || opcode == 2) {
            if (payload != 0) return -1;
            if (out_count == 0) {
                while (in_count > 0) out_stack[out_count++] = in_stack[--in_count];
            }
            if (out_count == 0) return -1;
            if (opcode == 1) {
                observed = out_stack[--out_count];
            } else {
                observed = out_stack[out_count - 1];
            }
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = (long)(in_count + out_count == 0);
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = (long)(in_count + out_count);
        } else {
            return -1;
        }
        if (returns_value) checksum += (long)(operation + 1) * (observed + 1000000);
    }
    for (usz index = 0; index < out_count; index++) {
        checksum += (long)(operation_count + index + 1) * (out_stack[out_count - index - 1] + 1000000);
    }
    for (usz index = 0; index < in_count; index++) {
        checksum += (long)(operation_count + out_count + index + 1) * (in_stack[index] + 1000000);
    }
    return checksum;
}
