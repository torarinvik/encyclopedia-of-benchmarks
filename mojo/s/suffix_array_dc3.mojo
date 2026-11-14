# Independent bounded DC3 implementation; see the package RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dc_symbol(s: InlineArray[Int, 16], n: Int, i: Int) -> Int:
    return s[i] if i < n else 0

fn dc_rank(r: InlineArray[Int, 16], n: Int, i: Int) -> Int:
    return r[i] if i < n else -1

fn dc_triple(s: InlineArray[Int, 16], n: Int, a: Int, b: Int) -> Int:
    for i in range(3):
        let x = dc_symbol(s, n, a + i)
        let y = dc_symbol(s, n, b + i)
        if x != y: return -1 if x < y else 1
    return 0

fn dc_suffix(s: InlineArray[Int, 16], n: Int, a: Int, b: Int) -> Bool:
    var i = a
    var j = b
    while i < n and j < n:
        if s[i] != s[j]: return s[i] < s[j]
        i += 1
        j += 1
    return i == n and j != n

fn dc_zero_before(s: InlineArray[Int, 16], ranks: InlineArray[Int, 16], n: Int, a: Int, b: Int) -> Bool:
    if s[a] != s[b]: return s[a] < s[b]
    return dc_rank(ranks, n, a + 1) < dc_rank(ranks, n, b + 1)

fn dc_merge_before(s: InlineArray[Int, 16], ranks: InlineArray[Int, 16], n: Int, zero: Int, sample: Int) -> Bool:
    if s[zero] != s[sample]: return s[zero] < s[sample]
    if sample % 3 == 1:
        return dc_rank(ranks, n, zero + 1) < dc_rank(ranks, n, sample + 1)
    let a = dc_symbol(s, n, zero + 1)
    let b = dc_symbol(s, n, sample + 1)
    if a != b: return a < b
    return dc_rank(ranks, n, zero + 2) < dc_rank(ranks, n, sample + 2)

fn dc3(s: InlineArray[Int, 16], n: Int, inout output: InlineArray[Int, 16]):
    if n <= 3:
        for i in range(n): output[i] = i
        for i in range(1, n):
            let value = output[i]
            var j = i
            while j > 0 and dc_suffix(s, n, value, output[j - 1]):
                output[j] = output[j - 1]
                j -= 1
            output[j] = value
        return
    var samples = InlineArray[Int, 16](fill=0)
    var sample_count = 0
    for i in range(1, n):
        if i % 3 != 0:
            samples[sample_count] = i
            sample_count += 1
    for i in range(1, sample_count):
        let value = samples[i]
        var j = i
        while j > 0 and dc_triple(s, n, value, samples[j - 1]) < 0:
            samples[j] = samples[j - 1]
            j -= 1
        samples[j] = value
    var names = InlineArray[Int, 16](fill=0)
    var name = 0
    for i in range(sample_count):
        if i == 0 or dc_triple(s, n, samples[i - 1], samples[i]) != 0: name += 1
        names[samples[i]] = name
    var reduced = InlineArray[Int, 16](fill=0)
    var reduced_count = 0
    var pos = 1
    while pos < n:
        reduced[reduced_count] = names[pos]
        reduced_count += 1
        pos += 3
    let group_one = reduced_count
    reduced[reduced_count] = 0
    reduced_count += 1
    pos = 2
    while pos < n:
        reduced[reduced_count] = names[pos]
        reduced_count += 1
        pos += 3
    var reduced_order = InlineArray[Int, 16](fill=0)
    dc3(reduced, reduced_count, reduced_order)
    var ordered = InlineArray[Int, 16](fill=0)
    var ranks = InlineArray[Int, 16](fill=-1)
    var ordered_count = 0
    for i in range(reduced_count):
        let r = reduced_order[i]
        if r == group_one: continue
        let original = 1 + 3 * r if r < group_one else 2 + 3 * (r - group_one - 1)
        ordered[ordered_count] = original
        ranks[original] = ordered_count
        ordered_count += 1
    var zeros = InlineArray[Int, 16](fill=0)
    var zero_count = 0
    pos = 0
    while pos < n:
        zeros[zero_count] = pos
        zero_count += 1
        pos += 3
    for i in range(1, zero_count):
        let value = zeros[i]
        var j = i
        while j > 0 and dc_zero_before(s, ranks, n, value, zeros[j - 1]):
            zeros[j] = zeros[j - 1]
            j -= 1
        zeros[j] = value
    var a = 0
    var b = 0
    var out_index = 0
    while a < zero_count and b < ordered_count:
        if dc_merge_before(s, ranks, n, zeros[a], ordered[b]):
            output[out_index] = zeros[a]
            a += 1
        else:
            output[out_index] = ordered[b]
            b += 1
        out_index += 1
    while a < zero_count:
        output[out_index] = zeros[a]
        a += 1
        out_index += 1
    while b < ordered_count:
        output[out_index] = ordered[b]
        b += 1
        out_index += 1

@export("suffix_array_dc3")
fn suffix_array_dc3(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 18: return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > 16 or Int(length) != 1 + Int(raw_count): return -1
    let n = Int(raw_count)
    var symbols = InlineArray[Int, 16](fill=0)
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > 255: return -1
        symbols[i] = Int(input[i + 1]) + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var suffixes = InlineArray[Int, 16](fill=0)
    dc3(symbols, n, suffixes)
    for i in range(n):
        let bits = UInt64(suffixes[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(8 * n)
