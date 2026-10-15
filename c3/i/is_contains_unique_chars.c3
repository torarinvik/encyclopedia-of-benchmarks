module is_contains_unique_chars;

const usz MAX_LENGTH = 4096;

fn long is_contains_unique_chars(long* values, usz length)
    @export("is_contains_unique_chars")
{
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 0 || values[i] > 127) return -1;
    }
    ulong[2] seen;
    seen[0] = 0ul;
    seen[1] = 0ul;
    for (usz i = 0; i < length; i++) {
        ulong value = (ulong)values[i];
        usz word = (usz)(value / 64);
        ulong mask = 1ul << (ulong)(value % 64ul);
        if ((seen[word] & mask) != 0) return 0;
        seen[word] |= mask;
    }
    return 1;
}
