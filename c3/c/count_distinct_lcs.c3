// Uncompiled duplicate-aware distinct-LCS counting draft.
module count_distinct_lcs;
fn long count_distinct_lcs(long* input, usz length) @export("count_distinct_lcs") {
    if (input == null || length < 2 || length > 131) return -1;
    long nr = input[0], mr = input[1];
    if (nr < 0 || nr > 64 || mr < 0 || mr > 64 || length != (usz)(2+nr+mr)) return -1;
    usz n = (usz)nr, m = (usz)mr;
    for (usz i = 2; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    int[65] prev_len = zeroed, curr_len = zeroed;
    long[65] prev_count = zeroed, curr_count = zeroed;
    for (usz j = 0; j <= m; j++) prev_count[j] = 1;
    for (usz i = 1; i <= n; i++) {
        curr_len[0] = 0; curr_count[0] = 1;
        for (usz j = 1; j <= m; j++) {
            if (input[1+i] == input[1+n+j]) {
                curr_len[j] = prev_len[j-1]+1; curr_count[j] = prev_count[j-1];
            } else {
                int best = prev_len[j] > curr_len[j-1] ? prev_len[j] : curr_len[j-1];
                long count = 0;
                if (prev_len[j] == best) count += prev_count[j];
                if (curr_len[j-1] == best) count += curr_count[j-1];
                if (prev_len[j-1] == best) count -= prev_count[j-1];
                curr_len[j] = best; curr_count[j] = (count+1000000007)%1000000007;
            }
        }
        for (usz j = 0; j <= m; j++) { prev_len[j] = curr_len[j]; prev_count[j] = curr_count[j]; }
    }
    return prev_count[m];
}
