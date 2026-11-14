from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("p2p_chord_finger_lookup")
fn p2p_chord_finger_lookup(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 116: return -1
    if input[0] < 1 or input[0] > 6 or input[1] < 2 or input[1] > 16: return -1
    let bits = Int(input[0])
    let n = Int(input[1])
    let ring = 1 << bits
    if n > ring or input[2] < 0 or input[2] >= Int64(n) or input[3] < 0 or input[3] >= Int64(ring): return -1
    if length != c_size_t(4+n+n*bits): return -1
    var ids = InlineArray[Int, 16](fill=0)
    var fingers = InlineArray[Int, 96](fill=0)
    for i in range(n):
        let raw = input[4+i]
        if raw < 0 or raw >= Int64(ring): return -1
        if i > 0 and raw <= Int64(ids[i-1]): return -1
        ids[i] = Int(raw)
    for node in range(n):
        for level in range(bits):
            let raw = input[4+n+node*bits+level]
            if raw < 0 or raw >= Int64(n): return -1
            let target = (ids[node] + (1 << level)) % ring
            var successor = 0
            while successor < n and ids[successor] < target: successor += 1
            if successor == n: successor = 0
            if Int(raw) != successor: return -1
            fingers[node*bits+level] = successor
    let key = Int(input[3])
    var owner = 0
    while owner < n and ids[owner] < key: owner += 1
    if owner == n: owner = 0
    var route = InlineArray[Int, 16](fill=0)
    var route_length = 1
    var current = Int(input[2])
    route[0] = current
    for _ in range(n):
        if current == owner: break
        let target_distance = (ids[owner] - ids[current] + ring) % ring
        var chosen = -1
        for offset in range(bits):
            let level = bits-1-offset
            let candidate = fingers[current*bits+level]
            let progress = (ids[candidate] - ids[current] + ring) % ring
            if progress > 0 and progress <= target_distance:
                chosen = candidate
                break
        if chosen < 0 or route_length >= n: return -1
        for i in range(route_length):
            if route[i] == chosen: return -1
        current = chosen
        route[route_length] = current
        route_length += 1
    if current != owner: return -1
    let bytes = 8*route_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(route_length):
        let value = UInt64(ids[route[i]])
        for b in range(8): output[8*i+b] = UInt8((value >> UInt(8*b)) & 255)
    return Int64(bytes)
