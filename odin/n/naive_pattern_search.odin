package naive_pattern_search
import "core:c"
@(export)
naive_pattern_search :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
    if v == nil || n < 2 || n > 512 do return -2
    tn, pn := v[0], v[1]
    if tn < 0 || tn > 255 || pn < 0 || pn > tn || n != c.size_t(2+tn+pn) do return -2
    for i: c.size_t=0; i<c.size_t(tn+pn); i+=1 { if v[2+i] < 0 || v[2+i] > 127 do return -2 }
    if pn == 0 do return -1
    for start: i64=0; start<=tn-pn; start+=1 {
        j: i64=0
        for j<pn && v[2+c.size_t(start+j)] == v[2+c.size_t(tn+j)] { j+=1 }
        if j==pn do return start
    }
    return -1
}
