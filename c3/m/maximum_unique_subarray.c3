module maximum_unique_subarray;

// Maximize the sum of a contiguous window with distinct values.
fn long maximum_unique_subarray(long* values, usz length) @export("maximum_unique_subarray") {
    if (length > 256 || (length != 0 && values == null)) return -1;
    long[512] keys;
    usz[512] last_seen;
    bool[512] occupied;
    for (usz slot = 0; slot < 512; slot++) { keys[slot] = 0; last_seen[slot] = 0; occupied[slot] = false; }
    usz left = 0;
    long window_sum = 0;
    long best = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 1 || value > 10000) return -1;
        usz slot = (usz)value % 512;
        while (occupied[slot] && keys[slot] != value) slot = (slot + 1) % 512;
        usz previous = last_seen[slot];
        while (left < previous) {
            window_sum -= values[left];
            left++;
        }
        window_sum += value;
        keys[slot] = value;
        last_seen[slot] = index + 1;
        occupied[slot] = true;
        if (window_sum > best) best = window_sum;
    }
    return best;
}
