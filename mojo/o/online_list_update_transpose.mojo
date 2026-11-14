from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("online_list_update_transpose")
fn online_list_update_transpose(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 42: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 32: return -1
    let n = Int(input[0])
    let requests = Int(input[1])
    if length != c_size_t(2+n+requests): return -1
    var order = InlineArray[Int, 8](fill=0)
    var seen = InlineArray[Bool, 8](fill=False)
    for i in range(n):
        let raw = input[2+i]
        if raw < 0 or raw >= Int64(n): return -1
        let item = Int(raw)
        if seen[item]: return -1
        seen[item] = True
        order[i] = item
    for i in range(requests):
        if input[2+n+i] < 0 or input[2+n+i] >= Int64(n): return -1
    var positions = InlineArray[Int, 32](fill=0)
    var total = 0
    for i in range(requests):
        let item = Int(input[2+n+i])
        var position = 0
        while position < n and order[position] != item: position += 1
        if position == n: return -1
        positions[i] = position+1
        total += position+1
        if position > 0:
            order[position] = order[position-1]
            order[position-1] = item
            total += 1
    let words = 1+n+requests
    let bytes = 8*words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(words):
        var value = 0
        if word == 0: value = total
        elif word <= n: value = order[word-1]
        else: value = positions[word-1-n]
        let bits = UInt64(value)
        for b in range(8): output[8*word+b] = UInt8((bits >> UInt(8*b)) & 255)
    return Int64(bytes)
