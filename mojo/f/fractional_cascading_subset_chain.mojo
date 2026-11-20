from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime FCSC_MAX_M = 8
comptime FCSC_MAX_Q = 8
comptime FCSC_MAX_N = 16
comptime FCSC_MAX_LENGTH = 147
comptime FCSC_NO_SUCCESSOR = 34

fn fcsc_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > FCSC_MAX_LENGTH: return -1
    if input[0] < 2 or input[0] > FCSC_MAX_M or input[1] < 1 or input[1] > FCSC_MAX_Q: return -1
    let m = Int(input[0])
    let q = Int(input[1])
    var catalogs = InlineArray[Int64, FCSC_MAX_M * FCSC_MAX_N](fill=0)
    var sizes = InlineArray[Int, FCSC_MAX_M](fill=0)
    var queries = InlineArray[Int64, FCSC_MAX_Q](fill=0)
    var cursor = 2
    for i in range(m):
        if cursor >= length or input[cursor] < 1 or input[cursor] > FCSC_MAX_N: return -1
        let n = Int(input[cursor])
        cursor += 1
        if cursor + n > length: return -1
        sizes[i] = n
        for j in range(n):
            let key = input[cursor]
            cursor += 1
            if key < -16 or key > 16: return -1
            if j > 0 and catalogs[i * FCSC_MAX_N + j - 1] >= key: return -1
            catalogs[i * FCSC_MAX_N + j] = key
        if i > 0:
            var parent_pos = 0
            var child_pos = 0
            while parent_pos < sizes[i - 1] and child_pos < n:
                let parent_key = catalogs[(i - 1) * FCSC_MAX_N + parent_pos]
                let child_key = catalogs[i * FCSC_MAX_N + child_pos]
                if parent_key < child_key:
                    parent_pos += 1
                elif parent_key == child_key:
                    parent_pos += 1
                    child_pos += 1
                else:
                    return -1
            if child_pos != n: return -1
    if cursor + q != length: return -1
    for i in range(q):
        queries[i] = input[cursor + i]
        if queries[i] < -17 or queries[i] > 17: return -1

    var bridges = InlineArray[Int, (FCSC_MAX_M - 1) * (FCSC_MAX_N + 1)](fill=0)
    for i in range(m - 1):
        var child = 0
        for slot in range(sizes[i]):
            while child < sizes[i + 1] and catalogs[(i + 1) * FCSC_MAX_N + child] < catalogs[i * FCSC_MAX_N + slot]:
                child += 1
            bridges[i * (FCSC_MAX_N + 1) + slot] = child
        bridges[i * (FCSC_MAX_N + 1) + sizes[i]] = sizes[i + 1]

    var checksum: Int64 = 0
    for qi in range(q):
        var low = 0
        var high = sizes[0]
        while low < high:
            let middle = (low + high) // 2
            if catalogs[middle] < queries[qi]: low = middle + 1
            else: high = middle
        var slot = low
        for ci in range(m):
            let code = catalogs[ci * FCSC_MAX_N + slot] + 17 if slot < sizes[ci] else FCSC_NO_SUCCESSOR
            checksum += Int64(qi + 1) * Int64(ci + 1) * code
            if ci + 1 < m: slot = bridges[ci * (FCSC_MAX_N + 1) + slot]
    checksum

@export("fractional_cascading_subset_chain")
fn fractional_cascading_subset_chain(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(FCSC_MAX_LENGTH): return -1
    fcsc_impl(input, Int(length))
