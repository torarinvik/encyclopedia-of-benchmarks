from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("bit_list_update")
fn bit_list_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 50: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 32: return -1
    let n = Int(input[0])
    let requests = Int(input[1])
    if length != c_size_t(2+2*n+requests): return -1
    var order = InlineArray[Int, 8](fill=0)
    var seen = InlineArray[Bool, 8](fill=False)
    var bits = InlineArray[Int, 8](fill=0)
    for i in range(n):
        let raw = input[2+i]
        if raw < 0 or raw >= Int64(n): return -1
        let item = Int(raw)
        if seen[item]: return -1
        seen[item] = True
        order[i] = item
        let bit = input[2+n+requests+i]
        if bit != 0 and bit != 1: return -1
        bits[i] = Int(bit)
    for i in range(requests):
        if input[2+n+i] < 0 or input[2+n+i] >= Int64(n): return -1
    var positions = InlineArray[Int, 32](fill=0)
    var total = 0
    for time in range(requests):
        let item = Int(input[2+n+time])
        var position = 0
        while position < n and order[position] != item: position += 1
        if position == n: return -1
        positions[time] = position+1
        total += position+1
        bits[item] ^= 1
        if bits[item] == 1:
            while position > 0:
                order[position] = order[position-1]
                position -= 1
            order[0] = item
    let words = 1+2*n+requests
    let bytes = 8*words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(words):
        var value = 0
        if word == 0: value = total
        elif word <= n: value = order[word-1]
        elif word <= n+requests: value = positions[word-1-n]
        else: value = bits[word-1-n-requests]
        let bits64 = UInt64(value)
        for b in range(8): output[8*word+b] = UInt8((bits64 >> UInt(8*b)) & 255)
    return Int64(bytes)
