module unrolled_linked_list;

fn long unrolled_linked_list_benchmark(long* values, usz length) @export("unrolled_linked_list_benchmark") {
    if (length > 1024) return -1;
    long[2560] chunks;
    usz[512] counts;
    long[512] next;
    for (usz i = 0; i < 512; i++) next[i] = -1;
    usz blocks = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < -1000000 || value > 1000000) return -1;
        if (blocks == 0) { blocks = 1; counts[0] = 1; chunks[0] = value; continue; }
        usz tail = blocks - 1;
        if (counts[tail] < 4) { chunks[tail * 5 + counts[tail]] = value; counts[tail]++; }
        else {
            usz keep = counts[tail] / 2 + 1; usz moved = counts[tail] - keep;
            for (usz j = 0; j < moved; j++) chunks[blocks * 5 + j] = chunks[tail * 5 + keep + j];
            counts[tail] = keep; chunks[blocks * 5 + moved] = value; counts[blocks] = moved + 1; next[tail] = (long)blocks; blocks++;
        }
    }
    long checksum = 0; usz index = 0;
    usz b = 0; while (b < 512) { for (usz j = 0; j < counts[b]; j++) { checksum += (long)(index + 1) * (chunks[b * 5 + j] + 1000000); index++; } if (next[b] < 0) break; b = (usz)next[b]; }
    return checksum;
}
