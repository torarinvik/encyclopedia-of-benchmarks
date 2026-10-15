module hash_xor8;

fn long hash_xor8(long* values, usz length) @export("hash_xor8") {
    if (length > 100001 || (values == null && length != 0)) return -1;
    for (usz i = 0; i < length && values[i] != 0; i++)
        if (values[i] < 0 || values[i] > 127) return -1;
    uint hash = 0;
    for (usz i = 0; i < length && values[i] != 0; i++) hash = (hash + (uint)values[i]) & 0xff;
    return (long)(((hash ^ 0xff) + 1) & 0xff);
}
