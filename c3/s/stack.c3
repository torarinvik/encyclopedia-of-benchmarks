module stack;

const long INVALID_RESULT = -1;

// Bounded array-backed integer stack used by the shared operation-trace benchmark.
fn long stack_benchmark(long* values, usz length) @export("stack_benchmark")
{
    if (length > 1024 || length % 2 != 0) return INVALID_RESULT;
    usz operation_count = length / 2;
    long[256] data_stack;
    usz top = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[2 * operation];
        long payload = values[2 * operation + 1];
        long observed = 0;
        bool returns_value = true;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || top == 256) return INVALID_RESULT;
            data_stack[top] = payload;
            top++;
            returns_value = false;
        } else if (opcode == 1) {
            if (payload != 0 || top == 0) return INVALID_RESULT;
            top--;
            observed = data_stack[top];
        } else if (opcode == 2) {
            if (payload != 0 || top == 0) return INVALID_RESULT;
            observed = data_stack[top - 1];
        } else if (opcode == 3) {
            if (payload != 0) return INVALID_RESULT;
            observed = top == 0 ? 1 : 0;
        } else {
            return INVALID_RESULT;
        }
        if (returns_value) checksum += (long)(operation + 1) * (observed + 1000000);
    }
    for (usz index = 0; index < top; index++) {
        checksum += (long)(operation_count + index + 1) * (data_stack[index] + 1000000);
    }
    return checksum;
}
