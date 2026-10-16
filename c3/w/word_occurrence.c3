module word_occurrence;
const usz MAX_INPUT = 1024;
const usz MAX_ENTRIES = 512;
fn bool ws(uchar c) { return (c >= 9 && c <= 13) || (c >= 28 && c <= 32); }
fn void put32(uchar* output, usz* pos, uint value) { uint bits = value; for (usz i = 0; i < 4; i++) { output[*pos] = (uchar)(bits & 255); *pos += 1; bits >>= 8; } }
fn long word_occurrence(long* input, usz length, uchar* output, usz capacity) @export("word_occurrence") {
    if (input == null || length < 1 || length > 1025) return -1;
    long n_arg = input[0]; if (n_arg < 0 || n_arg > 1024 || length != (usz)n_arg + 1) return -1;
    usz n = (usz)n_arg; uchar[MAX_INPUT] text;
    for (usz i = 0; i < n; i++) { long value = input[i + 1]; if (value < 0 || value > 127) return -1; text[i] = (uchar)value; }
    usz[MAX_ENTRIES] starts, lens; uint[MAX_ENTRIES] counts; usz entries = 0, i = 0;
    while (i < n) {
        while (i < n && ws(text[i])) i++;
        if (i == n) break;
        usz start = i; while (i < n && !ws(text[i])) i++;
        usz len = i - start, j = 0;
        for (; j < entries; j++) { if (lens[j] != len) continue; usz q = 0; for (; q < len && text[starts[j] + q] == text[start + q]; q++) {} if (q == len) break; }
        if (j == entries) { if (entries >= MAX_ENTRIES) return -1; starts[j] = start; lens[j] = len; counts[j] = 0; entries++; }
        counts[j]++;
    }
    usz need = 4; for (usz j = 0; j < entries; j++) need += 8 + lens[j];
    if (output == null || capacity < need) return -2;
    usz pos = 0; put32(output, &pos, (uint)entries);
    for (usz j = 0; j < entries; j++) { put32(output, &pos, (uint)lens[j]); for (usz q = 0; q < lens[j]; q++) output[pos++] = text[starts[j] + q]; put32(output, &pos, counts[j]); }
    return (long)pos;
}
