# Independent bounded TAR filename search; MIT source attribution is in the package license.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tarfind")
fn tarfind(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1602: return -1
    if input[0] < 1 or input[0] > 35 or input[1] < 1 or input[1] > 5: return -1
    let records = Int(input[0])
    let queries = Int(input[1])
    let end = Int(length)
    var offsets = InlineArray[Int, 40](fill=0)
    var sizes = InlineArray[Int, 40](fill=0)
    var cursor = 2
    for i in range(records + queries):
        if cursor >= end: return -1
        let size = input[cursor]
        cursor += 1
        if size < 5 or size > 39 or cursor + Int(size) > end: return -1
        offsets[i] = cursor
        sizes[i] = Int(size)
        for j in range(Int(size)):
            if input[cursor + j] < 65 or input[cursor + j] > 90: return -1
        cursor += Int(size)
    if cursor != end: return -1
    var matches = InlineArray[UInt8, 5](fill=255)
    for q in range(queries):
        let query = records + q
        for record in range(records):
            if sizes[record] != sizes[query]: continue
            var j = 0
            while j < sizes[query] and input[offsets[record] + j] == input[offsets[query] + j]: j += 1
            if j == sizes[query]:
                matches[q] = UInt8(record)
                break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(queries): return -2
    for i in range(queries): output[i] = matches[i]
    return Int64(queries)
