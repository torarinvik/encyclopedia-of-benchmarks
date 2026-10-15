module base64_to_binary;
fn bool edge_space(long v) { return (v >= 9 && v <= 13) || v == 32; }
fn int digit(long c) {
    if (c >= 'A' && c <= 'Z') return (int)(c - 'A');
    if (c >= 'a' && c <= 'z') return (int)(c - 'a' + 26);
    if (c >= '0' && c <= '9') return (int)(c - '0' + 52);
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}
fn long base64_to_binary(long* input, usz length, char* output, usz capacity) @export("base64_to_binary") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    usz n = (usz)input[0]; if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    usz begin = 0, end = n;
    while (begin < end && edge_space(input[begin + 1])) begin++;
    while (end > begin && edge_space(input[end])) end--;
    if (begin == end) return -1;
    bool negative = input[begin + 1] == '-'; if (negative) begin++;
    for (usz i = begin; i < end; i++) if (digit(input[i + 1]) < 0) return -1;
    usz out_len = (end - begin) * 6 + (negative ? 1 : 0);
    if (capacity < out_len || output == null) return -2;
    usz offset = 0; if (negative) { output[offset] = '-'; offset++; }
    for (usz i = begin; i < end; i++) {
        uint value = (uint)digit(input[i + 1]);
        for (int bit = 5; bit >= 0; bit--) { output[offset] = (char)('0' + ((value >> bit) & 1)); offset++; }
    }
    return (long)out_len;
}
