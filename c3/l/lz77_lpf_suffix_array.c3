module lz77_lpf_suffix_array;
const MAX_TEXT = 32, MAX_INPUT = 34, MAX_OUTPUT = 512;

fn bool suffix_less(long* text, usz n, usz a, usz b) {
    while (a < n && b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        a++; b++;
    }
    return a == n && b != n;
}

fn usz lcp(long* text, usz n, long source, usz target) {
    if (source < 0) return 0;
    usz length = 0, p = (usz)source;
    while (target + length < n && text[p + length] == text[target + length]) length++;
    return length;
}

fn void put64(uint8* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) { out[at + i] = (uint8)(bits & 255); bits >>= 8; }
}

fn long lz77_lpf_suffix_array(long* input, usz len, uint8* output, usz cap)
    @export("lz77_lpf_suffix_array") {
    if (input == null || len < 1 || len > MAX_INPUT || input[0] < 0 || input[0] > MAX_TEXT) return -1;
    usz n = (usz)input[0];
    if (len != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    long* text = input + 1;
    usz[MAX_TEXT] sa, inverse, stack;
    long[MAX_TEXT] previous, following;
    for (usz i = 0; i < n; i++) sa[i] = i;
    for (usz i = 1; i < n; i++) {
        usz value = sa[i], j = i;
        while (j > 0 && suffix_less(text, n, value, sa[j - 1])) { sa[j] = sa[j - 1]; j--; }
        sa[j] = value;
    }
    for (usz r = 0; r < n; r++) inverse[sa[r]] = r;
    usz top = 0;
    for (usz r = 0; r < n; r++) {
        while (top > 0 && sa[stack[top - 1]] > sa[r]) top--;
        previous[r] = top > 0 ? (long)stack[top - 1] : -1;
        stack[top++] = r;
    }
    top = 0;
    for (usz rr = n; rr > 0; rr--) {
        usz r = rr - 1;
        while (top > 0 && sa[stack[top - 1]] > sa[r]) top--;
        following[r] = top > 0 ? (long)stack[top - 1] : -1;
        stack[top++] = r;
    }
    uint8[MAX_OUTPUT] staged = zeroed;
    usz pairs = 0, pos = 0;
    while (pos < n) {
        usz rank = inverse[pos];
        long psv = previous[rank] >= 0 ? (long)sa[(usz)previous[rank]] : -1;
        long nsv = following[rank] >= 0 ? (long)sa[(usz)following[rank]] : -1;
        usz lp = lcp(text, n, psv, pos), ln = lcp(text, n, nsv, pos);
        long source = ln > lp ? nsv : psv;
        usz match = ln > lp ? ln : lp;
        if (match == 0) source = -1;
        put64(&staged[0], pairs * 16, source);
        put64(&staged[0], pairs * 16 + 8, (long)match);
        pairs++; pos += match > 0 ? match : 1;
    }
    usz bytes = pairs * 16;
    if (output == null || cap < bytes) return -2;
    for (usz i = 0; i < bytes; i++) output[i] = staged[i];
    return (long)bytes;
}
