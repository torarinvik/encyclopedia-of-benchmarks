from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dbms_delete_valid(input: UnsafePointer[Int64, ImmutAnyOrigin], at: Int) -> Bool:
    for d in range(4):
        let lo = input[at + d]
        let hi = input[at + 4 + d]
        if lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo >= hi: return False
    return True

fn dbms_delete_hit(input: UnsafePointer[Int64, ImmutAnyOrigin], at: Int) -> Bool:
    for d in range(4):
        if input[1 + d] > input[at + 4 + d] or input[at + d] > input[5 + d]: return False
    return True

@export("versabench_dbms_delete_entry")
fn versabench_dbms_delete_entry(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > 190: return -1
    if input[0] < 1 or input[0] > 4 or not dbms_delete_valid(input, 1): return -1
    let children = Int(input[0])
    let end = Int(length)
    var offsets = InlineArray[Int, 4](fill=0)
    var counts = InlineArray[Int, 4](fill=0)
    var seen = InlineArray[Bool, 32](fill=False)
    var cursor = 9
    for child in range(children):
        if cursor + 9 > end: return -1
        let count = input[cursor]
        if count < 1 or count > 4 or cursor + 9 + 9 * Int(count) > end: return -1
        offsets[child] = cursor
        counts[child] = Int(count)
        let bounds = cursor + 1
        if not dbms_delete_valid(input, bounds): return -1
        var lo = InlineArray[Int64, 4](fill=8)
        var hi = InlineArray[Int64, 4](fill=-8)
        for record in range(Int(count)):
            let at = cursor + 9 + 9 * record
            if not dbms_delete_valid(input, at): return -1
            let id = input[at + 8]
            if id < 0 or id >= 32: return -1
            if seen[Int(id)]: return -1
            seen[Int(id)] = True
            for d in range(4):
                if input[at + d] < lo[d]: lo[d] = input[at + d]
                if input[at + 4 + d] > hi[d]: hi[d] = input[at + 4 + d]
        for d in range(4):
            if input[bounds + d] != lo[d] or input[bounds + 4 + d] != hi[d]: return -1
        cursor += 9 + 9 * Int(count)
    if cursor != end: return -1
    var words = InlineArray[Int64, 181](fill=0)
    var used = 1
    var remaining = 0
    for child in range(children):
        let base = offsets[child]
        let branch_hit = dbms_delete_hit(input, base + 1)
        var retained = InlineArray[Int, 4](fill=0)
        var kept = 0
        var lo = InlineArray[Int64, 4](fill=8)
        var hi = InlineArray[Int64, 4](fill=-8)
        for record in range(counts[child]):
            let at = base + 9 + 9 * record
            if branch_hit and dbms_delete_hit(input, at): continue
            retained[kept] = at
            kept += 1
            for d in range(4):
                if input[at + d] < lo[d]: lo[d] = input[at + d]
                if input[at + 4 + d] > hi[d]: hi[d] = input[at + 4 + d]
        if kept == 0: continue
        remaining += 1
        words[used] = Int64(kept)
        used += 1
        for d in range(4): words[used + d] = lo[d]
        for d in range(4): words[used + 4 + d] = hi[d]
        used += 8
        for record in range(kept):
            for part in range(9): words[used + part] = input[retained[record] + part]
            used += 9
    words[0] = Int64(remaining)
    let bytes = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(used):
        var bits = bitcast[UInt64](words[word])
        for byte in range(8):
            output[8 * word + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
