module bidirectional_fm_index;

fn bool suffix_less(long* s, usz n, usz a0, usz b0) {
    usz a = a0, b = b0;
    while (a < n && b < n) {
        if (s[a] != s[b]) return s[a] < s[b];
        a++; b++;
    }
    return a == n && b != n;
}

fn void build_index(long* s, usz total, usz* cumulative, long* bwt) {
    usz[65] suffixes;
    usz[5] frequency = {0};
    for (usz i = 0; i < total; i++) suffixes[i] = i;
    for (usz i = 1; i < total; i++) {
        usz key = suffixes[i], j = i;
        while (j > 0 && suffix_less(s, total, key, suffixes[j - 1])) {
            suffixes[j] = suffixes[j - 1]; j--;
        }
        suffixes[j] = key;
    }
    for (usz i = 0; i < total; i++) {
        bwt[i] = s[(suffixes[i] + total - 1) % total];
        frequency[(usz)bwt[i]]++;
    }
    usz seen = 0;
    for (usz sym = 0; sym < 5; sym++) { cumulative[sym] = seen; seen += frequency[sym]; }
}

fn usz rank_before(long* bwt, usz end, usz symbol) {
    usz count = 0;
    for (usz i = 0; i < end; i++) if ((usz)bwt[i] == symbol) count++;
    return count;
}

fn long bidirectional_fm_index(long* input, usz length) @export("bidirectional_fm_index") {
    if (input == null || length < 2 || length > 195) return -1;
    long n0 = input[0], q0 = input[1];
    if (n0 < 0 || n0 > 64 || q0 < 0 || q0 > 64) return -1;
    usz n = (usz)n0, q = (usz)q0;
    if (length != 2 + n + 2 * q) return -1;
    long[65] forward_text;
    long[65] reverse_text;
    long[65] forward_bwt;
    long[65] reverse_bwt;
    for (usz i = 0; i < n; i++) {
        long sym = input[2 + i];
        if (sym < 1 || sym > 4) return -1;
        forward_text[i] = sym; reverse_text[n - 1 - i] = sym;
    }
    forward_text[n] = 0; reverse_text[n] = 0;
    for (usz i = 0; i < q; i++) {
        long side = input[2 + n + 2 * i], sym = input[3 + n + 2 * i];
        if ((side != 0 && side != 1) || sym < 1 || sym > 4) return -1;
    }
    usz total = n + 1;
    usz[5] forward_c, reverse_c;
    build_index(&forward_text[0], total, &forward_c[0], &forward_bwt[0]);
    build_index(&reverse_text[0], total, &reverse_c[0], &reverse_bwt[0]);
    usz fl = 0, fr = total, rl = 0, rr = total;
    long checksum = 0;
    for (usz op = 0; op < q; op++) {
        usz side = (usz)input[2 + n + 2 * op], sym = (usz)input[3 + n + 2 * op];
        usz old_fl = fl, old_fr = fr, old_rl = rl, old_rr = rr;
        if (side == 0) {
            fl = forward_c[sym] + rank_before(&forward_bwt[0], old_fl, sym);
            fr = forward_c[sym] + rank_before(&forward_bwt[0], old_fr, sym);
            usz start = old_rl;
            for (usz smaller = 0; smaller < sym; smaller++)
                start += rank_before(&forward_bwt[0], old_fr, smaller) - rank_before(&forward_bwt[0], old_fl, smaller);
            usz count = rank_before(&forward_bwt[0], old_fr, sym) - rank_before(&forward_bwt[0], old_fl, sym);
            rl = start; rr = start + count;
        } else {
            rl = reverse_c[sym] + rank_before(&reverse_bwt[0], old_rl, sym);
            rr = reverse_c[sym] + rank_before(&reverse_bwt[0], old_rr, sym);
            usz start = old_fl;
            for (usz smaller = 0; smaller < sym; smaller++)
                start += rank_before(&reverse_bwt[0], old_rr, smaller) - rank_before(&reverse_bwt[0], old_rl, smaller);
            usz count = rank_before(&reverse_bwt[0], old_rr, sym) - rank_before(&reverse_bwt[0], old_rl, sym);
            fl = start; fr = start + count;
        }
        checksum += (long)(op + 1) * (long)(fr - fl);
    }
    return checksum;
}
