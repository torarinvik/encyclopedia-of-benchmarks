from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime IBL_B = 4
comptime IBL_MAX_INITIAL = 16
comptime IBL_MAX_OPS = 64
comptime IBL_MAX_INSERTS = 32
comptime IBL_MAX_ACCESSES = 32
comptime IBL_MAX_NODES = 16
comptime IBL_MAX_ITEMS = 48
comptime IBL_MAX_PARSEABLE = 179
comptime IBL_STRIDE = 9

fn ibl_insert(inout blocks: InlineArray[Int64, 144], inout sizes: InlineArray[Int32, 16],
              inout next: InlineArray[Int32, 16], inout node_count: Int, index: Int, value: Int64):
    var node = 0
    var offset = 0
    while next[node] >= 0 and index > offset + Int(sizes[node]):
        offset += Int(sizes[node])
        node = Int(next[node])
    let local = index - offset
    var j = Int(sizes[node])
    while j > local:
        blocks[node * IBL_STRIDE + j] = blocks[node * IBL_STRIDE + j - 1]
        j -= 1
    blocks[node * IBL_STRIDE + local] = value
    sizes[node] += 1
    if sizes[node] > 2 * IBL_B:
        let fresh = node_count
        node_count += 1
        let first = Int(sizes[node]) - IBL_B
        for k in range(IBL_B):
            blocks[fresh * IBL_STRIDE + k] = blocks[node * IBL_STRIDE + first + k]
        sizes[fresh] = IBL_B
        sizes[node] -= IBL_B
        next[fresh] = next[node]
        next[node] = Int32(fresh)

fn ibl_get(blocks: InlineArray[Int64, 144], sizes: InlineArray[Int32, 16],
           next: InlineArray[Int32, 16], index: Int) -> Int64:
    var node = 0
    var offset = 0
    while index >= offset + Int(sizes[node]):
        offset += Int(sizes[node])
        node = Int(next[node])
    return blocks[node * IBL_STRIDE + index - offset]

@export("indexed_block_list")
fn indexed_block_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > IBL_MAX_PARSEABLE:
        return -1
    let n = Int(length)
    if input[0] < 0 or input[0] > IBL_MAX_INITIAL:
        return -1
    let initial = Int(input[0])
    if n < initial + 2:
        return -1
    for i in range(initial):
        if input[1 + i] < -1_000_000 or input[1 + i] > 1_000_000:
            return -1
    let raw_ops = input[1 + initial]
    if raw_ops < 0 or raw_ops > IBL_MAX_OPS:
        return -1
    var cursor = initial + 2
    var size = initial
    var inserts = 0
    var accesses = 0
    for _ in range(Int(raw_ops)):
        if cursor >= n:
            return -1
        if input[cursor] == 0:
            if cursor + 3 > n:
                return -1
            let raw_index = input[cursor + 1]
            let value = input[cursor + 2]
            if raw_index < 0 or raw_index > Int64(size) or value < -1_000_000 or value > 1_000_000:
                return -1
            inserts += 1
            if inserts > IBL_MAX_INSERTS:
                return -1
            size += 1
            cursor += 3
        elif input[cursor] == 1:
            if cursor + 2 > n:
                return -1
            let raw_index = input[cursor + 1]
            if raw_index < 0 or raw_index >= Int64(size):
                return -1
            accesses += 1
            if accesses > IBL_MAX_ACCESSES:
                return -1
            cursor += 2
        else:
            return -1
    if cursor != n or size > IBL_MAX_ITEMS:
        return -1
    let required = accesses * 8
    if required > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required)):
        return -2

    var blocks = InlineArray[Int64, 144]()
    var sizes = InlineArray[Int32, 16](fill=0)
    var next = InlineArray[Int32, 16](fill=-1)
    var answers = InlineArray[Int64, 32]()
    var node_count = 1
    for i in range(initial):
        ibl_insert(blocks, sizes, next, node_count, i, input[1 + i])
    let operation_count = Int(input[1 + initial])
    cursor = initial + 2
    var answer_count = 0
    for _ in range(operation_count):
        let opcode = input[cursor]
        let index = Int(input[cursor + 1])
        if opcode == 0:
            ibl_insert(blocks, sizes, next, node_count, index, input[cursor + 2])
            cursor += 3
        else:
            answers[answer_count] = ibl_get(blocks, sizes, next, index)
            answer_count += 1
            cursor += 2
    for i in range(answer_count):
        let bits = bitcast[UInt64](answers[i])
        for b in range(8):
            output[8 * i + b] = UInt8((bits >> (8 * b)) & UInt64(255))
    return Int64(required)
