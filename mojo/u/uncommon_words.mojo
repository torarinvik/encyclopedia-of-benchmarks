from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("uncommon_words")
fn uncommon_words(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1 or n > 1089: return -1
    let count = v[0]
    if count < 0 or count > 64: return -1
    var starts = InlineArray[Int, 64](fill=0); var lens = InlineArray[Int,64](fill=0); var freqs = InlineArray[Int,64](fill=0)
    var at = 1
    for i in range(Int(count)):
        if at >= Int(n): return -1
        let len = v[at]
        if len < 1 or len > 16 or at + 1 + Int(len) > Int(n): return -1
        starts[i] = at + 1; lens[i] = Int(len); freqs[i] = 1
        for j in range(Int(len)):
            if v[at+1+j] < 97 or v[at+1+j] > 122: return -1
        var found = False
        for prior in range(i):
            if lens[prior] != Int(len): continue
            var same = True
            for j in range(Int(len)):
                if v[starts[prior]+j] != v[at+1+j]: same = False
            if same:
                freqs[prior] += 1
                found = True
                break
        if found: freqs[i] = 0
        at += 1 + Int(len)
    if at != Int(n): return -1
    var bytes = InlineArray[UInt8, 1089](fill=0); var used = 0; var emitted = 0
    for i in range(Int(count)):
        if freqs[i] != 1: continue
        if emitted > 0: bytes[used] = 10; used += 1
        for j in range(lens[i]): bytes[used] = UInt8(v[starts[i]+j]); used += 1
        emitted += 1
    bytes[used] = 0; used += 1
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(used): return -2
    for i in range(used): out[i] = bytes[i]
    return Int64(used)
