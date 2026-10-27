module mmpfh_bucketing;

const long MAX_N = 32, MAX_Q = 32, BUCKET = 3, MAX_B = 11, MAX_WORDS = 100;

fn long lcp(long a, long b) {
    long count = 0;
    while (count < 16 && ((a >> (15 - count)) & 1) == ((b >> (15 - count)) & 1)) count += 1;
    return count;
}

fn void put_i64(char* out, usz pos, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[pos + b] = (char)((bits >> (8 * b)) & 255);
}

fn long mmpfh_bucketing(long* input, usz length, char* output, usz capacity)
    @export("mmpfh_bucketing") {
    if (input == null || length < 3 || length > 66) return -1;
    long n0 = input[0], q0 = input[1];
    if (n0 < 1 || n0 > MAX_N || q0 < 1 || q0 > MAX_Q || length != 2 + n0.usz() + q0.usz()) return -1;
    usz n = n0.usz(), q = q0.usz();
    long[MAX_N] keys, d0;
    long[MAX_Q] queries, ranks;
    for (usz i = 0; i < n; i++) {
        long x = input[2 + i];
        if (x < 0 || x > 65535 || (i > 0 && keys[i - 1] >= x)) return -1;
        keys[i] = x;
    }
    for (usz i = 0; i < q; i++) {
        long x = input[2 + n + i];
        if (x < 0 || x > 65535) return -1;
        queries[i] = x;
        bool found = false;
        for (usz j = 0; j < n; j++) if (keys[j] == x) found = true;
        if (!found) return -1;
    }
    usz buckets = (n + BUCKET.usz() - 1) / BUCKET.usz();
    long[MAX_B] lens, prefixes;
    for (usz b = 0; b < buckets; b++) {
        usz start = b * BUCKET.usz(), end = start + BUCKET.usz();
        if (end > n) end = n;
        long plen = end - start == 1 ? 16 : lcp(keys[start], keys[end - 1]);
        long prefix = plen == 0 ? 0 : keys[start] >> (16 - plen);
        lens[b] = plen; prefixes[b] = prefix;
        for (usz i = start; i < end; i++) d0[i] = plen;
    }
    for (usz i = 0; i < q; i++) {
        usz pos = 0;
        while (keys[pos] != queries[i]) pos++;
        long plen = d0[pos], prefix = plen == 0 ? 0 : queries[i] >> (16 - plen);
        usz b = 0;
        while (b < buckets && (lens[b] != plen || prefixes[b] != prefix)) b++;
        if (b == buckets) return -1;
        ranks[i] = (b * BUCKET.usz() + pos - b * BUCKET.usz()).long();
    }
    usz words = 3 + n + 3 * buckets + q;
    if (output == null || capacity < words * 8) return -2;
    long[MAX_WORDS] staged;
    usz k = 0;
    staged[k++] = n.long(); staged[k++] = buckets.long(); staged[k++] = q.long();
    for (usz i = 0; i < n; i++) staged[k++] = d0[i];
    for (usz b = 0; b < buckets; b++) { staged[k++] = lens[b]; staged[k++] = prefixes[b]; staged[k++] = b.long(); }
    for (usz i = 0; i < q; i++) staged[k++] = ranks[i];
    for (usz i = 0; i < words; i++) put_i64(output, i * 8, staged[i]);
    return (words * 8).long();
}
