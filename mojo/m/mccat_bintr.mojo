# Copyright (C) 1996 McGill University, McCAT System Group, and ACAPS Benchmark Administrator.
# Redistribution and modification are permitted when the copyright notice is retained;
# no warranty is provided. See the package README for the complete notice.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn bintr_count(left: InlineArray[Int, 64], right: InlineArray[Int, 64], node: Int) -> Int:
    if node < 0: return 0
    return 1 + bintr_count(left, right, left[node]) + bintr_count(left, right, right[node])

fn bintr_sum(values: InlineArray[Int64, 64], left: InlineArray[Int, 64], right: InlineArray[Int, 64], node: Int) -> Float64:
    if node < 0: return 0.0
    return Float64(values[node]) + bintr_sum(values, left, right, left[node]) + bintr_sum(values, left, right, right[node])

fn bintr_member(values: InlineArray[Int64, 64], left: InlineArray[Int, 64], right: InlineArray[Int, 64], node: Int, query: Int64) -> Bool:
    if node < 0: return False
    if values[node] == query: return True
    if bintr_member(values, left, right, left[node], query): return True
    return bintr_member(values, left, right, right[node], query)

@export("mccat_bintr")
fn mccat_bintr(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 103 or length > 166: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let n = Int(input[0])
    if Int(length) != n + 102 or input[n + 1] != 100: return -1
    for i in range(n):
        if input[1 + i] == 0 or input[1 + i] < -32768 or input[1 + i] > 32767: return -1
    for i in range(100):
        if input[n + 2 + i] == 0 or input[n + 2 + i] < -32768 or input[n + 2 + i] > 32767: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 33: return -2
    var values = InlineArray[Int64, 64](fill=0)
    var left = InlineArray[Int, 64](fill=-1)
    var right = InlineArray[Int, 64](fill=-1)
    values[0] = input[1]
    var used = 1
    for i in range(1, n):
        let value = input[1 + i]
        var node = 0
        while True:
            if value == values[node]: break
            if value < values[node]:
                if left[node] < 0:
                    left[node] = used
                    values[used] = value
                    used += 1
                    break
                node = left[node]
            else:
                if right[node] < 0:
                    right[node] = used
                    values[used] = value
                    used += 1
                    break
                node = right[node]
    let size = bintr_count(left, right, 0)
    let sum = bintr_sum(values, left, right, 0)
    let mean = sum / Float64(size)
    for i in range(33): output[i] = 0
    var count_bits = UInt64(size)
    for b in range(4):
        output[b] = UInt8(count_bits & 255)
        count_bits >>= 8
    var sum_bits = bitcast[UInt64](sum)
    var mean_bits = bitcast[UInt64](mean)
    for b in range(8):
        output[4 + b] = UInt8(sum_bits & 255)
        output[12 + b] = UInt8(mean_bits & 255)
        sum_bits >>= 8
        mean_bits >>= 8
    for i in range(100):
        if bintr_member(values, left, right, 0, input[n + 2 + i]):
            output[20 + i // 8] |= UInt8(1 << (i & 7))
    return 33
