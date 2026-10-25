module cbench_ispell_hash;
const usz MAX_WORD_BYTES = 64;
fn uint upper_ascii(uint c) {
    return c >= 97 && c <= 122 ? c - 32 : c;
}
fn long cbench_ispell_hash(long* values, usz length) @export("cbench_ispell_hash") {
    if (values == null || length == 0 || length > MAX_WORD_BYTES + 1) return -1;
    long table_size = values[0];
    if (table_size < 1 || table_size > 2147483647) return -1;
    usz count = length - 1;
    for (usz i = 0; i < count; i++) if (values[i + 1] < 1 || values[i + 1] > 127) return -1;
    uint h = 0;
    usz initial = count < 4 ? count : 4;
    for (usz i = 0; i < initial; i++) h = (h << 8) | upper_ascii((uint)values[i + 1]);
    for (usz i = initial; i < count; i++) { h = (h << 5) | (h >> 27); h = h ^ upper_ascii((uint)values[i + 1]); }
    return (long)(h % (uint)table_size);
}
