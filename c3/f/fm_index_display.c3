module fm_index_display;

const int MAX_TEXT = 32;
const int MAX_INPUT = 36;

fn bool suffix_less(long *text, usz n, usz a, usz b) {
    while (a < n && b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        a++; b++;
    }
    return a == n && b != n;
}

fn long fm_index_display(long *input, usz length, uint8 *output, usz capacity) @export("fm_index_display") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long n0 = input[0];
    if (n0 < 1 || n0 > MAX_TEXT || length != (usz)n0 + 4) return -1;
    usz n = (usz)n0;
    long left0 = input[n + 1], right0 = input[n + 2], stride0 = input[n + 3];
    if (left0 < 0 || right0 < left0 || right0 >= n0 || stride0 < 1 || stride0 > n0) return -1;
    usz left = (usz)left0, right = (usz)right0, stride = (usz)stride0, size = n + 1;
    long[MAX_TEXT + 1] text = zeroed;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < 1 || input[i + 1] > 4) return -1;
        text[i] = input[i + 1];
    }
    text[n] = 0;
    usz[MAX_TEXT + 1] sa;
    for (usz i = 0; i < size; i++) sa[i] = i;
    for (usz i = 1; i < size; i++) {
        usz key = sa[i], j = i;
        while (j > 0 && suffix_less(&text[0], size, key, sa[j - 1])) { sa[j] = sa[j - 1]; j--; }
        sa[j] = key;
    }
    usz[MAX_TEXT + 1] isa;
    long[MAX_TEXT + 1] bwt;
    usz[5] freq = zeroed;
    for (usz row = 0; row < size; row++) {
        usz pos = sa[row]; isa[pos] = row;
        bwt[row] = text[(pos + size - 1) % size];
        freq[(usz)bwt[row]]++;
    }
    usz[5] first, sum = 0;
    for (usz c = 0; c < 5; c++) { first[c] = sum; sum += freq[c]; }
    usz[5] seen = zeroed;
    usz[MAX_TEXT + 1] lf;
    for (usz row = 0; row < size; row++) { usz c = (usz)bwt[row]; lf[row] = first[c] + seen[c]++; }
    usz[MAX_TEXT + 1] sampled_isa;
    bool[MAX_TEXT + 1] sampled = zeroed;
    for (usz pos = 0; pos < n; pos++) if ((pos + 1) % stride == 0) { sampled[pos] = true; sampled_isa[pos] = isa[pos]; }
    sampled[n] = true; sampled_isa[n] = isa[n];
    usz sample = ((right + 1) / stride + 1) * stride - 1;
    if (sample > n) sample = n;
    if (!sampled[sample]) return -1;
    usz row = sampled_isa[sample], current = sample;
    while (current > right + 1) { row = lf[row]; current--; }
    uint8[MAX_TEXT] reversed;
    usz count = 0;
    while (current > left) { reversed[count++] = (uint8)bwt[row]; row = lf[row]; current--; }
    if (count != right - left + 1) return -1;
    if (output == null || capacity < count) return -2;
    for (usz i = 0; i < count; i++) output[i] = reversed[count - 1 - i];
    return (long)count;
}
