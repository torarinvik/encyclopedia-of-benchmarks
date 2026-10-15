module binary_to_base64;
const char[64] ALPHABET = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'};
fn bool edge_space(long value) { return (value >= 9 && value <= 13) || value == 32; }
fn long binary_to_base64(long* input, usz length, char* output, usz capacity) @export("binary_to_base64") {
    if (input == null || length < 2 || input[0] < 1 || input[0] > 256) return -1;
    usz n = (usz)input[0]; if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    usz begin = 0, end = n;
    while (begin < end && edge_space(input[1 + begin])) begin++;
    while (end > begin && edge_space(input[end])) end--;
    if (begin == end) return -1;
    bool negative = input[1 + begin] == '-'; if (negative) begin++;
    for (usz i = begin; i < end; i++) if (input[1 + i] != '0' && input[1 + i] != '1') return -1;
    usz bit_count = end - begin, padding = 6 - bit_count % 6, groups = (bit_count + padding) / 6;
    usz output_length = groups + (negative ? 1 : 0);
    if (capacity < output_length || output == null) return -2;
    usz offset = 0; if (negative) { output[offset] = '-'; offset++; }
    for (usz group = 0; group < groups; group++) {
        uint value = 0;
        for (usz bit = 0; bit < 6; bit++) {
            value <<= 1; usz position = group * 6 + bit;
            if (position >= padding && input[1 + begin + position - padding] == '1') value++;
        }
        output[offset] = ALPHABET[value]; offset++;
    }
    return (long)output_length;
}
