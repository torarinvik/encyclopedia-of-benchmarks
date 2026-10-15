module count_distinct_elements_in_window;

const MAX_N = 256;
const HASH_CAPACITY = 512;

fn usz hash_slot(int value) {
    ulong mixed = (ulong)(uint)value * 2654435761UL;
    return (usz)(((uint)mixed) >> 23);
}

fn usz find_slot(int* keys, bool* occupied, int value) {
    usz slot = hash_slot(value);
    for (usz probes = 0; probes < HASH_CAPACITY; probes++) {
        if (!occupied[slot] || keys[slot] == value) return slot;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return 0;
}

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long count_distinct_elements_in_window(long* input, usz length, char* output, usz capacity)
    @export("count_distinct_elements_in_window") {
    if (input == null || length < 3 || input[0] < 1 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (input[1] < 1 || input[1] > (long)n || length != n + 2) return -1;
    usz k = (usz)input[1], out_n = n - k + 1;
    for (usz i = 0; i < n; i++) if (input[i + 2] < -2147483648L || input[i + 2] > 2147483647L) return -1;
    if (output == null || capacity < out_n * 8) return -2;

    int[HASH_CAPACITY] keys;
    int[HASH_CAPACITY] counts = zeroed;
    bool[HASH_CAPACITY] occupied = zeroed;
    long distinct = 0;
    for (usz i = 0; i < k; i++) {
        int value = (int)input[i + 2];
        usz slot = find_slot(&keys[0], &occupied[0], value);
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot] == 0) distinct++;
        counts[slot]++;
    }
    put_i64_le(distinct, output, 0);
    for (usz i = k; i < n; i++) {
        int incoming = (int)input[i + 2];
        usz slot = find_slot(&keys[0], &occupied[0], incoming);
        if (!occupied[slot]) { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot] == 0) distinct++;
        counts[slot]++;
        int outgoing = (int)input[i - k + 2];
        slot = find_slot(&keys[0], &occupied[0], outgoing);
        counts[slot]--;
        if (counts[slot] == 0) distinct--;
        put_i64_le(distinct, output, (i - k + 1) * 8);
    }
    return (long)(out_n * 8);
}
