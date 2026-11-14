from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dbms_query_box_valid(input: UnsafePointer[Int64, ImmutAnyOrigin], at: Int) -> Bool:
    for d in range(4):
        let lo = input[at + d]
        let hi = input[at + 4 + d]
        if lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo >= hi: return False
    return True

fn dbms_query_intersects(input: UnsafePointer[Int64, ImmutAnyOrigin], at: Int) -> Bool:
    for d in range(4):
        if input[2 + d] > input[at + 4 + d] or input[at + d] > input[6 + d]: return False
    return True

@export("versabench_dbms_query")
fn versabench_dbms_query(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > 277: return -1
    if input[0] < 1 or input[0] > 7 or input[1] < 0 or input[1] >= input[0]: return -1
    if not dbms_query_box_valid(input, 2): return -1
    let n = Int(input[0])
    let root = Int(input[1])
    let end = Int(length)
    var offsets = InlineArray[Int, 7](fill=0)
    var levels = InlineArray[Int, 7](fill=0)
    var counts = InlineArray[Int, 7](fill=0)
    var parents = InlineArray[Int, 7](fill=0)
    var seen = InlineArray[Bool, 32](fill=False)
    var leaf_count = 0
    var cursor = 10
    for node in range(n):
        if cursor + 2 > end: return -1
        let level = input[cursor]
        let count = input[cursor + 1]
        if level < 0 or level > 2 or count < 1 or count > 4: return -1
        cursor += 2
        if cursor + 9 * Int(count) > end: return -1
        offsets[node] = cursor
        levels[node] = Int(level)
        counts[node] = Int(count)
        for entry in range(Int(count)):
            let at = cursor + 9 * entry
            if not dbms_query_box_valid(input, at): return -1
            let reference = input[at + 8]
            if level == 0:
                if reference < 0 or reference >= 32 or leaf_count >= 16: return -1
                if seen[Int(reference)]: return -1
                seen[Int(reference)] = True
                leaf_count += 1
            else:
                if reference < 0 or reference >= Int64(n): return -1
                parents[Int(reference)] += 1
                if parents[Int(reference)] > 1: return -1
        cursor += 9 * Int(count)
    if cursor != end or parents[root] != 0: return -1
    for node in range(n):
        if node != root and parents[node] != 1: return -1
        if levels[node] == 0: continue
        for entry in range(counts[node]):
            let at = offsets[node] + 9 * entry
            let child = Int(input[at + 8])
            if levels[child] != levels[node] - 1: return -1
            for subentry in range(counts[child]):
                let sub = offsets[child] + 9 * subentry
                for d in range(4):
                    if input[at + d] > input[sub + d] or input[at + 4 + d] < input[sub + 4 + d]: return -1
    var stack = InlineArray[Int, 7](fill=0)
    var top = 1
    stack[0] = root
    var hits = InlineArray[Int64, 16](fill=0)
    var hit_count = 0
    while top > 0:
        top -= 1
        let node = stack[top]
        if levels[node] == 0:
            for entry in range(counts[node]):
                let at = offsets[node] + 9 * entry
                if dbms_query_intersects(input, at):
                    hits[hit_count] = input[at + 8]
                    hit_count += 1
        else:
            var entry = counts[node]
            while entry > 0:
                entry -= 1
                let at = offsets[node] + 9 * entry
                if dbms_query_intersects(input, at):
                    stack[top] = Int(input[at + 8])
                    top += 1
    let bytes = 8 * hit_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(hit_count):
        output[8 * i] = UInt8(hits[i])
        for b in range(1, 8): output[8 * i + b] = 0
    return Int64(bytes)
