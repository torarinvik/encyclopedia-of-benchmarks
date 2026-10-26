module gbbs_approximate_set_cover;

fn void store_le(char* out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) { out[offset + i] = (char)(bits & 255); bits >>= 8; }
}

// Clean-room bounded GBBS approximate set-cover profile; see package MIT notice.
long gbbs_approximate_set_cover(long* input, usz length, char* output, usz capacity)
        @export("gbbs_approximate_set_cover") {
    if (input == null || length < 2 || length > 10) return -1;
    long ns64 = input[0];
    if (ns64 < 1 || ns64 > 8) return -1;
    usz ns = (usz)ns64, ne = ns;
    if (length != 1 + ns) return -1;
    ushort valid = (ushort)((1 << ne) - 1);
    ushort[8] sets = zeroed;
    for (usz s = 0; s < ns; s += 1) {
        if (input[1 + s] < 0 || (((ulong)input[1 + s]) & ~((ulong)valid)) != 0) return -1;
        sets[s] = (ushort)input[1 + s];
        if ((sets[s] & (1 << s)) != 0) return -1;
    }
    for (usz u = 0; u < ns; u += 1)
        for (usz v = 0; v < ns; v += 1)
            if (((sets[u] >> v) & 1) != ((sets[v] >> u) & 1)) return -1;
    if (output == null || capacity < 16) return -2;
    ushort uncovered = valid, selected = 0;
    usz[8] bucket = zeroed;
    for (usz s = 0; s < ns; s += 1) {
        ushort bits = sets[s];
        while (bits != 0) { bits &= bits - 1; bucket[s] += 1; }
    }
    usz round = 0;
    while (uncovered != 0) {
        usz[8] degree = zeroed;
        usz top = 0;
        for (usz s = 0; s < ns; s += 1) if (bucket[s] > top) top = bucket[s];
        if (top == 0) break;
        bool[8] eligible = zeroed;
        usz eligible_count = 0;
        for (usz s = 0; s < ns; s += 1) if (bucket[s] == top) {
            ushort bits = sets[s] & uncovered;
            while (bits != 0) { bits &= bits - 1; degree[s] += 1; }
            bucket[s] = degree[s];
            eligible[s] = degree[s] >= top;
            if (eligible[s]) eligible_count += 1;
        }
        usz[8] priority = zeroed;
        usz priority_count = 0;
        for (usz r = 0; r < ns; r += 1) {
            usz s = (round + r) % ns;
            if (eligible[s]) { priority[priority_count] = s; priority_count += 1; }
        }
        usz[8] wins = zeroed;
        for (usz e = 0; e < ne; e += 1) {
            ushort bit = (ushort)(1 << e);
            if ((uncovered & bit) == 0) continue;
            for (usz r = 0; r < priority_count; r += 1) {
                usz s = priority[r];
                if ((sets[s] & bit) != 0) { wins[s] += 1; break; }
            }
        }
        ushort round_cover = 0;
        for (usz s = 0; s < ns; s += 1)
            if (eligible[s] && wins[s] >= top) round_cover |= (ushort)(1 << s);
        if (round_cover == 0 && eligible_count != 0) return -1;
        selected |= round_cover;
        ushort covered = 0;
        for (usz s = 0; s < ns; s += 1) if ((round_cover & (1 << s)) != 0) covered |= sets[s];
        uncovered &= ~covered;
        for (usz s = 0; s < ns; s += 1) if ((round_cover & (1 << s)) != 0) bucket[s] = 0;
        round += 1;
    }
    store_le(output, 0, (long)selected);
    store_le(output, 8, (long)uncovered);
    return 16;
}
