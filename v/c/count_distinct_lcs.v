// Uncompiled duplicate-aware distinct-LCS counting draft.
@[export: 'count_distinct_lcs']
pub fn count_distinct_lcs(input &i64, length usize) i64 {
    if length < 2 || length > 131 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nr := input[0]; mr := input[1]
        if nr < 0 || nr > 64 || mr < 0 || mr > 64 || length != usize(2+nr+mr) { return -1 }
        n := int(nr); m := int(mr)
        for i in 2 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
        mut prev_len := [65]int{}
        mut curr_len := [65]int{}
        mut prev_count := [65]i64{}
        mut curr_count := [65]i64{}
        for j in 0 .. m+1 { prev_count[j] = 1 }
        for i in 1 .. n+1 {
            curr_len[0] = 0; curr_count[0] = 1
            for j in 1 .. m+1 {
                if input[1+i] == input[1+n+j] {
                    curr_len[j] = prev_len[j-1]+1; curr_count[j] = prev_count[j-1]
                } else {
                    best := if prev_len[j] > curr_len[j-1] { prev_len[j] } else { curr_len[j-1] }
                    mut count := i64(0)
                    if prev_len[j] == best { count += prev_count[j] }
                    if curr_len[j-1] == best { count += curr_count[j-1] }
                    if prev_len[j-1] == best { count -= prev_count[j-1] }
                    curr_len[j] = best; curr_count[j] = (count+1000000007)%1000000007
                }
            }
            for j in 0 .. m+1 { prev_len[j] = curr_len[j]; prev_count[j] = curr_count[j] }
        }
        return prev_count[m]
    }
}
