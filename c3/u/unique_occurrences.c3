module unique_occurrences;

// Check whether every present value has a distinct occurrence count.
fn long unique_occurrences(long* values, usz length) @export("unique_occurrences") {
    if (length == 0) return 1;
    if (length > 1000 || values == null) return -1;
    ulong first = (ulong)values[0];
    if (length == 1) return first + 1000 <= 2000 ? 1 : -1;

    ulong largest_biased = 0;
    ulong different_bits = 0;
    for (usz index = 0; index < length; ++index) {
        ulong value = (ulong)values[index];
        ulong biased = value + 1000;
        different_bits |= value ^ first;
        largest_biased = biased > largest_biased ? biased : largest_biased;
    }
    if (largest_biased > 2000) return -1;
    if (different_bits == 0) return 1;

    ushort[2001] counts = {};
    ushort[44] touched = {};
    usz distinct = 0;
    for (usz index = 0; index < length; ++index) {
        usz slot = (usz)((ulong)values[index] + 1000);
        if (counts[slot]++ == 0) {
            usz next_distinct = distinct + 1;
            if (next_distinct * (next_distinct + 1) > 2 * length) return 0;
            touched[distinct] = (ushort)slot;
            distinct = next_distinct;
        }
    }
    ulong[16] seen = {};
    for (usz index = 0; index < distinct; ++index) {
        usz frequency = counts[touched[index]];
        usz word = frequency >> 6;
        ulong bit = (ulong)1 << (frequency & 63);
        if ((seen[word] & bit) != 0) return 0;
        seen[word] |= bit;
    }
    return 1;
}
