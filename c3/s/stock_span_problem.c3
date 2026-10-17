module stock_span_problem;

// Return source-compatible spans for a bounded price sequence.
fn long stock_span_problem(long* input, usz length, char* output, usz capacity)
    @export("stock_span_problem") {
    if (input == null || length < 2 || length > 66) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > 64) return -1;
    usz count = (usz)count_value;
    if (length != count + 1) return -1;
    for (usz day = 0; day < count; day++)
        if (input[day + 1] < -2147483648 || input[day + 1] > 2147483647) return -1;

    usz output_bytes = count * 8;
    if (output == null || capacity < output_bytes) return -2;
    usz decreasing[64];
    usz top = 0;
    for (usz day = 0; day < count; day++) {
        long price = input[day + 1];
        while (top > 0 && input[decreasing[top - 1] + 1] <= price) top--;
        usz span = top == 0 ? day + 1 : day - decreasing[top - 1];
        ulong encoded = (ulong)span;
        for (usz byte = 0; byte < 8; byte++)
            output[day * 8 + byte] = (char)((encoded >> (byte * 8)) & 255);
        decreasing[top++] = day;
    }
    (long)count
}
