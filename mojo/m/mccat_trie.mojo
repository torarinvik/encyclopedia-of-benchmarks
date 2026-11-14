# Copyright (C) 1996 McGill University, McCAT System Group, and ACAPS Benchmark Administrator.
# Redistribution and modification are permitted when the copyright notice is retained;
# no warranty is provided. See the package LICENSE.txt for the complete notice.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mccat_trie")
fn mccat_trie(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2113: return -1
    if input[0] < 0 or input[0] > 64: return -1
    let count = Int(input[0])
    let end = Int(length)
    var starts = InlineArray[Int, 64](fill=0)
    var sizes = InlineArray[Int, 64](fill=0)
    var cursor = 1
    for i in range(count):
        if cursor >= end: return -1
        let size = input[cursor]
        cursor += 1
        if size < 1 or size > 32 or cursor + Int(size) > end: return -1
        starts[i] = cursor
        sizes[i] = Int(size)
        for j in range(Int(size)):
            if input[cursor + j] < 33 or input[cursor + j] > 126: return -1
        cursor += Int(size)
    if cursor != end: return -1
    var chars = InlineArray[UInt8, 2049](fill=0)
    var terminal = InlineArray[Bool, 2049](fill=False)
    var continuation = InlineArray[Int, 2049](fill=0)
    var alternative = InlineArray[Int, 2049](fill=0)
    var root = 0
    var used = 0
    for word in range(count):
        var previous = 0
        var node = root
        for offset in range(sizes[word]):
            let character = UInt8(input[starts[word] + offset])
            var prior = 0
            while node != 0 and chars[node] != character:
                prior = node
                node = alternative[node]
            if node == 0:
                used += 1
                node = used
                chars[node] = character
                if prior != 0: alternative[prior] = node
                elif previous != 0: continuation[previous] = node
                else: root = node
            if offset + 1 == sizes[word]: terminal[node] = True
            previous = node
            node = continuation[node]
    var stack_nodes = InlineArray[Int, 2049](fill=0)
    var stack_depths = InlineArray[Int, 2049](fill=0)
    var prefix = InlineArray[UInt8, 32](fill=0)
    var staged = InlineArray[UInt8, 2112](fill=0)
    var top = 0
    if root != 0:
        stack_nodes[0] = root
        top = 1
    var written = 0
    while top > 0:
        top -= 1
        let node = stack_nodes[top]
        let depth = stack_depths[top]
        prefix[depth] = chars[node]
        if terminal[node]:
            for i in range(depth + 1):
                staged[written] = prefix[i]
                written += 1
            staged[written] = 10
            written += 1
        if alternative[node] != 0:
            stack_nodes[top] = alternative[node]
            stack_depths[top] = depth
            top += 1
        if continuation[node] != 0:
            stack_nodes[top] = continuation[node]
            stack_depths[top] = depth + 1
            top += 1
    if written > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written)): return -2
    for i in range(written): output[i] = staged[i]
    return Int64(written)
