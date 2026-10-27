module psi_suffix_array_access;

const usz MAX_N = 32;
const usz MAX_INPUT = 67;
const usz MAX_OUTPUT = 16;

fn void put_u64(uint8* output, usz word, ulong value) {
    for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (uint8)(value >> (byte * 8));
}

fn long psi_suffix_array_access(long* input, usz length, uint8* output, usz capacity)
    @export("psi_suffix_array_access") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long n0 = input[0], query0 = input[1], stride0 = input[2];
    if (n0 < 1 || n0 > 32 || query0 < 0 || query0 >= n0 || stride0 < 1 || stride0 > n0 || length != (usz)(3 + 2 * n0)) return -1;
    usz n = (usz)n0, query = (usz)query0, stride = (usz)stride0;
    bool[32] destinations;
    bool[32] visited;
    for (usz i = 0; i < n; i++) { destinations[i] = false; visited[i] = false; }
    for (usz i = 0; i < n; i++) {
        long next = input[3 + i], sample = input[3 + n + i];
        if (next < 0 || (ulong)next >= (ulong)n || destinations[(usz)next] || sample < 0 || sample > n0) return -1;
        destinations[(usz)next] = true;
    }
    usz anchor = n;
    for (usz i = 0; i < n; i++) if (input[3 + n + i] != 0) { anchor = i; break; }
    if (anchor == n) return -1;
    long anchor_value = input[3 + n + anchor];
    if ((anchor_value - 1) % stride0 != 0) return -1;
    ulong[32] full_sa;
    for (usz i = 0; i < n; i++) full_sa[i] = 0;
    usz rank = anchor;
    long value = anchor_value;
    for (usz step = 0; step < n; step++) {
        if (visited[rank]) return -1;
        visited[rank] = true;
        full_sa[rank] = (ulong)value;
        rank = (usz)input[3 + rank];
        value = value == n0 ? 1 : value + 1;
    }
    if (rank != anchor || value != anchor_value) return -1;
    for (usz i = 0; i < n; i++) {
        long expected = (full_sa[i] - 1) % stride == 0 ? (long)full_sa[i] : 0;
        if (input[3 + n + i] != expected) return -1;
    }
    rank = query;
    usz hops = 0;
    while (input[3 + n + rank] == 0) {
        rank = (usz)input[3 + rank];
        hops++;
        if (hops >= stride) return -1;
    }
    long position0 = input[3 + n + rank] - 1 - (long)hops;
    position0 %= n0;
    if (position0 < 0) position0 += n0;
    if (output == null || capacity < MAX_OUTPUT) return -2;
    put_u64(output, 0, (ulong)(position0 + 1));
    put_u64(output, 1, (ulong)hops);
    return (long)MAX_OUTPUT;
}
