from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dbms_insert_valid(input: UnsafePointer[Int64, ImmutAnyOrigin], at: Int) -> Bool:
    for d in range(4):
        let lo = input[at + d]
        let hi = input[at + 4 + d]
        if lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo >= hi: return False
    return True

@export("versabench_dbms_insert_entry")
fn versabench_dbms_insert_entry(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 11 or length > 105: return -1
    if input[0] < 0 or input[0] > 2 or input[1] < 0 or input[1] >= 32: return -1
    if not dbms_insert_valid(input, 2): return -1
    let depth = Int(input[0])
    let end = Int(length)
    var offsets = InlineArray[Int, 2](fill=0)
    var counts = InlineArray[Int, 2](fill=0)
    var choices = InlineArray[Int, 2](fill=0)
    var cursor = 10
    for level in range(depth):
        if cursor >= end: return -1
        let count = input[cursor]
        cursor += 1
        if count < 1 or count > 4 or cursor + 8 * Int(count) > end: return -1
        offsets[level] = cursor
        counts[level] = Int(count)
        var best: Int64 = 65536
        for child in range(Int(count)):
            let at = cursor + 8 * child
            if not dbms_insert_valid(input, at): return -1
            var joined: Int64 = 1
            var original: Int64 = 1
            for d in range(4):
                var lo = input[at + d]
                var hi = input[at + 4 + d]
                if input[2 + d] < lo: lo = input[2 + d]
                if input[6 + d] > hi: hi = input[6 + d]
                joined *= hi - lo
                original *= input[at + 4 + d] - input[at + d]
            let penalty = joined - original
            if penalty < best:
                best = penalty
                choices[level] = child
        cursor += 8 * Int(count)
    if cursor >= end: return -1
    let leaf_count = input[cursor]
    cursor += 1
    if leaf_count < 0 or leaf_count > 3 or (depth > 0 and leaf_count == 0): return -1
    if cursor + 9 * Int(leaf_count) != end: return -1
    var seen = InlineArray[Bool, 32](fill=False)
    var pre = InlineArray[Int64, 8](fill=0)
    for d in range(4):
        pre[d] = 8
        pre[4 + d] = -8
    for record in range(Int(leaf_count)):
        let at = cursor + 9 * record
        if not dbms_insert_valid(input, at): return -1
        let id = input[at + 8]
        if id < 0 or id >= 32: return -1
        if seen[Int(id)] or id == input[1]: return -1
        seen[Int(id)] = True
        for d in range(4):
            if input[at + d] < pre[d]: pre[d] = input[at + d]
            if input[at + 4 + d] > pre[4 + d]: pre[4 + d] = input[at + 4 + d]
    var level = depth
    while level > 0:
        level -= 1
        let selected = offsets[level] + 8 * choices[level]
        for d in range(8):
            if input[selected + d] != pre[d]: return -1
        for d in range(4):
            pre[d] = 8
            pre[4 + d] = -8
        for child in range(counts[level]):
            let at = offsets[level] + 8 * child
            for d in range(4):
                if input[at + d] < pre[d]: pre[d] = input[at + d]
                if input[at + 4 + d] > pre[4 + d]: pre[4 + d] = input[at + 4 + d]
    var box = InlineArray[Int64, 8](fill=0)
    for d in range(8): box[d] = input[2 + d]
    for record in range(Int(leaf_count)):
        let at = cursor + 9 * record
        for d in range(4):
            if input[at + d] < box[d]: box[d] = input[at + d]
            if input[at + 4 + d] > box[4 + d]: box[4 + d] = input[at + 4 + d]
    var words = InlineArray[Int64, 28](fill=0)
    words[0] = Int64(depth)
    words[1] = input[1]
    for d in range(depth): words[2 + d] = Int64(choices[d])
    var used = 2 + depth
    for d in range(8): words[used + d] = box[d]
    used += 8
    level = depth
    while level > 0:
        level -= 1
        for child in range(counts[level]):
            if child == choices[level]: continue
            let at = offsets[level] + 8 * child
            for d in range(4):
                if input[at + d] < box[d]: box[d] = input[at + d]
                if input[at + 4 + d] > box[4 + d]: box[4 + d] = input[at + 4 + d]
        for d in range(8): words[used + d] = box[d]
        used += 8
    let bytes = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(used):
        var bits = bitcast[UInt64](words[word])
        for byte in range(8):
            output[8 * word + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
