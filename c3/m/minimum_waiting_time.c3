module minimum_waiting_time;

fn long minimum_waiting_time(long* values, usz length) @export("minimum_waiting_time") {
    if (length > 64 || (length != 0 && values == null)) return -9223372036854775807L - 1;
    long[64] durations;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 0 || values[i] > 1000) return -9223372036854775807L - 1;
        durations[i] = values[i];
    }
    for (usz i = 1; i < length; i++) {
        long key = durations[i];
        usz j = i;
        while (j > 0 && durations[j - 1] > key) {
            durations[j] = durations[j - 1];
            j--;
        }
        durations[j] = key;
    }
    long total = 0;
    for (usz i = 0; i < length; i++) total += durations[i] * (long)(length - i - 1);
    return total;
}
