# BYTEmark by Rick Grehan/BYTE; Unix port by Uwe F. Mayer. See package LICENSE.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("nbench_huffman_compression")
fn nbench_huffman_compression(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 129: return -1
    let nv = input[0]
    if nv < 1 or nv > 128 or length != c_size_t(1+Int(nv)): return -1
    let n = Int(nv)
    var text = List[Int](capacity=n+1)
    for i in range(n):
        let value = input[1+i]
        if value < 32 or value > 47: return -1
        text.append(Int(value))
    text.append(0)
    var frequency = List[Float32](length=512, fill=0.0)
    var parent = List[Int](length=512, fill=32000)
    var left = List[Int](length=512, fill=-1)
    var right = List[Int](length=512, fill=-1)
    for symbol in text: frequency[symbol] += Float32(1.0)
    for i in range(256):
        if frequency[i] != 0.0:
            frequency[i] /= Float32(n+1)
            parent[i] = -1
    var root = 255
    while True:
        var first = -1
        var second = -1
        var low1 = Float32(2.0)
        var low2 = Float32(2.0)
        for i in range(root+1):
            if parent[i] < 0 and frequency[i] < low1:
                first = i; low1 = frequency[i]
        if first < 0: break
        for i in range(root+1):
            if parent[i] < 0 and i != first and frequency[i] < low2:
                second = i; low2 = frequency[i]
        if second < 0: break
        root += 1
        parent[first] = root; parent[second] = root
        frequency[root] = low1+low2
        left[root] = first; right[root] = second; parent[root] = -2
    if root < 256 or left[root] < 0: return -1
    var stream = List[UInt8](length=258, fill=0)
    var bit_count = 0
    for symbol in text:
        var path = List[Int](capacity=30)
        var node = symbol
        while parent[node] != -2:
            let p = parent[node]
            if p < 0 or p >= 512 or len(path) >= 30: return -1
            var direction = 1
            if left[p] == node: direction = 0
            path.append(direction)
            node = p
        for i in range(len(path)):
            if path[len(path)-1-i] != 0: stream[bit_count >> 3] |= UInt8(1 << (bit_count & 7))
            bit_count += 1
    var bit = 0
    var decoded = 0
    while bit < bit_count:
        var node = root
        while left[node] != -1:
            if bit >= bit_count: return -1
            let direction = (stream[bit >> 3] >> (bit & 7)) & 1
            if direction == 0: node = left[node]
            else: node = right[node]
            bit += 1
        if decoded >= len(text) or node != text[decoded]: return -1
        decoded += 1
    if decoded != len(text): return -1
    let stream_bytes = (bit_count+7)//8
    let bytes = 4+stream_bytes
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for j in range(4): output[j] = UInt8((bit_count >> (8*j)) & 255)
    for i in range(stream_bytes): output[4+i] = stream[i]
    return Int64(bytes)
