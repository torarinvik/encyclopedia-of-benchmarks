from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mwp_search(pattern: UnsafePointer[Int64, ImmutAnyOrigin], pn: Int, text: UnsafePointer[Int64, ImmutAnyOrigin], tn: Int, pi: Int, ti: Int, mut starts: InlineArray[Int, 128], mut lengths: InlineArray[Int, 128]) -> Bool:
    if pi == pn: return ti == tn
    if ti == tn: return False
    let symbol = Int(pattern[pi]); let known = lengths[symbol]
    if known != 0:
        if known > tn-ti: return False
        for off in range(known):
            if text[starts[symbol]+off] != text[ti+off]: return False
        return mwp_search(pattern,pn,text,tn,pi+1,ti+known,mut starts,mut lengths)
    for end in range(ti+1,tn+1):
        let candidate = end-ti; var used = False
        for oi in range(pi):
            let other = Int(pattern[oi])
            if other == symbol or lengths[other] != candidate: continue
            var equal = True
            for off in range(candidate):
                if text[starts[other]+off] != text[ti+off]: equal = False
            if equal: used = True; break
        if used: continue
        starts[symbol] = ti; lengths[symbol] = candidate
        if mwp_search(pattern,pn,text,tn,pi+1,end,mut starts,mut lengths): return True
        lengths[symbol] = 0
    return False

@export("match_word_pattern")
fn match_word_pattern(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 43: return -1
    if v[0] < 0 or v[0] > 8 or v[1] < 0 or v[1] > 32: return -1
    let pn = Int(v[0]); let tn = Int(v[1])
    if n != c_size_t(2+pn+tn): return -1
    for i in range(pn+tn):
        if v[2+i] < 0 or v[2+i] > 127: return -1
    var starts = InlineArray[Int,128](fill=0); var lengths = InlineArray[Int,128](fill=0)
    return 1 if mwp_search(v+2,pn,v+2+pn,tn,0,0,mut starts,mut lengths) else 0
