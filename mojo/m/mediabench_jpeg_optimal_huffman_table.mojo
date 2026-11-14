# Clean-room IJG JPEG table-generation profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mediabench_jpeg_optimal_huffman_table")
fn mediabench_jpeg_optimal_huffman_table(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 41: return -1
    if input[0] < 1 or input[0] > 20: return -1
    let count = Int(input[0])
    if length != c_size_t(1+2*count): return -1
    var frequencies = InlineArray[Int64, 257](fill=0)
    for i in range(count):
        let symbol = input[1+2*i]; let frequency = input[2+2*i]
        if symbol < 0 or symbol > 255 or frequency < 1 or frequency > 1000000: return -1
        if frequencies[Int(symbol)] != 0: return -1
        frequencies[Int(symbol)] = frequency
    let bytes = 17+count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    frequencies[256] = 1
    var sizes = InlineArray[Int, 257](fill=0)
    var next = InlineArray[Int, 257](fill=-1)
    var bits = InlineArray[Int, 33](fill=0)
    while True:
        var first = -1; var second = -1
        var best: Int64 = 1000000000
        for i in range(257):
            if frequencies[i] != 0 and frequencies[i] <= best:
                best = frequencies[i]; first = i
        best = 1000000000
        for i in range(257):
            if frequencies[i] != 0 and frequencies[i] <= best and i != first:
                best = frequencies[i]; second = i
        if second < 0: break
        frequencies[first] += frequencies[second]; frequencies[second] = 0
        var node = first
        sizes[node] += 1
        while next[node] >= 0:
            node = next[node]; sizes[node] += 1
        next[node] = second
        node = second; sizes[node] += 1
        while next[node] >= 0:
            node = next[node]; sizes[node] += 1
    for i in range(257):
        if sizes[i] > 32: return -1
        if sizes[i] > 0: bits[sizes[i]] += 1
    var level = 32
    while level > 16:
        while bits[level] > 0:
            var shorter = level-2
            while shorter >= 0 and bits[shorter] == 0: shorter -= 1
            if shorter < 0 or bits[level] < 2: return -1
            bits[level] -= 2; bits[level-1] += 1
            bits[shorter+1] += 2; bits[shorter] -= 1
        level -= 1
    var longest = 16
    while longest > 0 and bits[longest] == 0: longest -= 1
    if longest == 0: return -1
    bits[longest] -= 1
    var staged = InlineArray[UInt8, 37](fill=0)
    staged[0] = UInt8(count)
    for i in range(1,17): staged[i] = UInt8(bits[i])
    var used = 17
    for size in range(1,33):
        for symbol in range(256):
            if sizes[symbol] == size:
                if used >= bytes: return -1
                staged[used] = UInt8(symbol); used += 1
    if used != bytes: return -1
    for i in range(bytes): output[i] = staged[i]
    return Int64(bytes)
