module mediabench_jpeg_optimal_huffman_table;

const int MAX_SYMBOLS = 20;
const int MAX_CLEN = 32;

// Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
fn long mediabench_jpeg_optimal_huffman_table(long* input, usz length, uchar* output, usz capacity)
    @export("mediabench_jpeg_optimal_huffman_table") {
    if (input == null || length < 3 || length > 41) return -1;
    if (input[0] < 1 || input[0] > MAX_SYMBOLS) return -1;
    int count = (int)input[0];
    if (length != (usz)(1 + 2 * count)) return -1;
    for (int i = 0; i < count; i++) {
        long symbol = input[1 + 2 * i], frequency = input[2 + 2 * i];
        if (symbol < 0 || symbol > 255 || frequency < 1 || frequency > 1000000) return -1;
        for (int j = 0; j < i; j++) if (input[1 + 2 * j] == symbol) return -1;
    }
    usz output_size = (usz)(17 + count);
    if (output == null || capacity < output_size) return -2;
    long[257] freq = {};
    int[257] codesize = {};
    int[257] others;
    int[MAX_CLEN + 1] bits = {};
    for (int i = 0; i < 257; i++) others[i] = -1;
    for (int i = 0; i < count; i++) freq[(int)input[1 + 2 * i]] = input[2 + 2 * i];
    freq[256] = 1;
    for (;;) {
        int c1 = -1, c2 = -1;
        long value = 1000000000;
        for (int i = 0; i <= 256; i++) if (freq[i] != 0 && freq[i] <= value) { value = freq[i]; c1 = i; }
        value = 1000000000;
        for (int i = 0; i <= 256; i++) if (freq[i] != 0 && freq[i] <= value && i != c1) { value = freq[i]; c2 = i; }
        if (c2 < 0) break;
        freq[c1] += freq[c2]; freq[c2] = 0;
        codesize[c1]++;
        int branch = c1;
        while (others[branch] >= 0) { branch = others[branch]; codesize[branch]++; }
        others[branch] = c2;
        codesize[c2]++;
        branch = c2;
        while (others[branch] >= 0) { branch = others[branch]; codesize[branch]++; }
    }
    for (int i = 0; i <= 256; i++) if (codesize[i] != 0) {
        if (codesize[i] > MAX_CLEN) return -1;
        bits[codesize[i]]++;
    }
    for (int i = MAX_CLEN; i > 16; i--) while (bits[i] > 0) {
        int j = i - 2;
        while (j >= 0 && bits[j] == 0) j--;
        if (j < 0 || bits[i] < 2) return -1;
        bits[i] -= 2; bits[i - 1]++; bits[j + 1] += 2; bits[j]--;
    }
    int longest = 16;
    while (longest > 0 && bits[longest] == 0) longest--;
    if (longest == 0) return -1;
    bits[longest]--;
    int symbol_count = 0;
    for (int size = 1; size <= MAX_CLEN; size++) for (int symbol = 0; symbol <= 255; symbol++)
        if (codesize[symbol] == size) symbol_count++;
    if (symbol_count != count) return -1;
    output[0] = (uchar)count;
    for (int i = 1; i <= 16; i++) output[i] = (uchar)bits[i];
    usz used = 17;
    for (int size = 1; size <= MAX_CLEN; size++) for (int symbol = 0; symbol <= 255; symbol++)
        if (codesize[symbol] == size) output[used++] = (uchar)symbol;
    return (long)used;
}
