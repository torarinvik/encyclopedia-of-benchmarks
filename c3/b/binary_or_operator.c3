module binary_or_operator;

fn long binary_or_operator(long* input, usz length, char* output, usz capacity) @export("binary_or_operator") {
    if (input == null || length != 2 || input[0] < 0 || input[0] > 2147483647 || input[1] < 0 || input[1] > 2147483647) return -1;
    ulong a = (ulong)input[0], b = (ulong)input[1];
    ulong largest = a > b ? a : b;
    usz width = 1;
    while (largest > 1) { width++; largest >>= 1; }
    usz output_length = width + 2;
    if (capacity < output_length || output == null) return -2;
    ulong result = a | b;
    output[0] = '0'; output[1] = 'b';
    for (usz i = 0; i < width; i++) {
        usz bit = width - 1 - i;
        output[2 + i] = (char)(((result >> bit) & 1) != 0 ? '1' : '0');
    }
    return (long)output_length;
}
