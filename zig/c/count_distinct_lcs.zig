// Uncompiled duplicate-aware distinct-LCS counting draft.
export fn count_distinct_lcs(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 131) return -1;
    const nr = input[0]; const mr = input[1];
    if (nr < 0 or nr > 64 or mr < 0 or mr > 64 or length != @as(usize,@intCast(2+nr+mr))) return -1;
    const n: usize = @intCast(nr); const m: usize = @intCast(mr);
    for (2..length) |i| if (input[i] < 0 or input[i] > 255) { return -1; };
    var prev_len = [_]usize{0} ** 65;
    var curr_len = [_]usize{0} ** 65;
    var prev_count = [_]i64{1} ** 65;
    var curr_count = [_]i64{0} ** 65;
    for (1..n+1) |i| {
        curr_len[0] = 0; curr_count[0] = 1;
        for (1..m+1) |j| {
            if (input[1+i] == input[1+n+j]) {
                curr_len[j] = prev_len[j-1]+1; curr_count[j] = prev_count[j-1];
            } else {
                const best = @max(prev_len[j], curr_len[j-1]);
                var count: i64 = 0;
                if (prev_len[j] == best) count += prev_count[j];
                if (curr_len[j-1] == best) count += curr_count[j-1];
                if (prev_len[j-1] == best) count -= prev_count[j-1];
                curr_len[j] = best; curr_count[j] = @mod(count+1000000007,1000000007);
            }
        }
        prev_len = curr_len; prev_count = curr_count;
    }
    return prev_count[m];
}
