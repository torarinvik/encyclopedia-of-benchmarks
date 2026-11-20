# Uncompiled duplicate-aware distinct-LCS counting draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_distinct_lcs")
fn count_distinct_lcs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131: return -1
    let nr = input[0]
    let mr = input[1]
    if nr < 0 or nr > 64 or mr < 0 or mr > 64 or length != c_size_t(2+nr+mr): return -1
    let n = Int(nr)
    let m = Int(mr)
    for i in range(2,Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    var prev_len = InlineArray[Int,65](fill=0)
    var curr_len = InlineArray[Int,65](fill=0)
    var prev_count = InlineArray[Int64,65](fill=1)
    var curr_count = InlineArray[Int64,65](fill=0)
    for i in range(1,n+1):
        curr_len[0] = 0
        curr_count[0] = 1
        for j in range(1,m+1):
            if input[1+i] == input[1+n+j]:
                curr_len[j] = prev_len[j-1]+1
                curr_count[j] = prev_count[j-1]
            else:
                let best = prev_len[j] if prev_len[j] > curr_len[j-1] else curr_len[j-1]
                var count = Int64(0)
                if prev_len[j] == best: count += prev_count[j]
                if curr_len[j-1] == best: count += curr_count[j-1]
                if prev_len[j-1] == best: count -= prev_count[j-1]
                curr_len[j] = best
                curr_count[j] = (count+1000000007)%1000000007
        for j in range(m+1):
            prev_len[j] = curr_len[j]
            prev_count[j] = curr_count[j]
    return prev_count[m]
