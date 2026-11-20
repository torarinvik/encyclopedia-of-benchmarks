// Uncompiled duplicate-aware distinct-LCS counting draft.
package count_distinct_lcs
import "core:c"
@(export)
count_distinct_lcs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 131 do return -1
    nr, mr := input[0], input[1]
    if nr < 0 || nr > 64 || mr < 0 || mr > 64 || length != c.size_t(2+nr+mr) do return -1
    n, m := int(nr), int(mr)
    for i := 2; i < int(length); i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
    prev_len: [65]int = {}
    curr_len: [65]int = {}
    prev_count: [65]i64 = {}
    curr_count: [65]i64 = {}
    for j := 0; j <= m; j += 1 { prev_count[j] = 1 }
    for i := 1; i <= n; i += 1 {
        curr_len[0] = 0; curr_count[0] = 1
        for j := 1; j <= m; j += 1 {
            if input[1+i] == input[1+n+j] {
                curr_len[j] = prev_len[j-1]+1; curr_count[j] = prev_count[j-1]
            } else {
                best := max(prev_len[j], curr_len[j-1]); count: i64 = 0
                if prev_len[j] == best { count += prev_count[j] }
                if curr_len[j-1] == best { count += curr_count[j-1] }
                if prev_len[j-1] == best { count -= prev_count[j-1] }
                curr_len[j] = best; curr_count[j] = (count+1000000007)%1000000007
            }
        }
        for j := 0; j <= m; j += 1 { prev_len[j] = curr_len[j]; prev_count[j] = curr_count[j] }
    }
    return prev_count[m]
}
