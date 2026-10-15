module unique_occurrences;

// Check whether every present value has a distinct occurrence count.
fn long unique_occurrences(long* values, usz length) @export("unique_occurrences") {
    if (length > 1000 || (length != 0 && values == null)) return -1;
    long[2001] counts;
    bool[1001] seen_frequencies;
    for (usz index = 0; index < 2001; index++) counts[index] = 0;
    for (usz index = 0; index < 1001; index++) seen_frequencies[index] = false;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < -1000 || value > 1000) return -1;
        counts[(usz)(value + 1000)]++;
    }
    for (usz index = 0; index < 2001; index++) {
        long frequency = counts[index];
        if (frequency == 0) continue;
        if (seen_frequencies[(usz)frequency]) return 0;
        seen_frequencies[(usz)frequency] = true;
    }
    return 1;
}
