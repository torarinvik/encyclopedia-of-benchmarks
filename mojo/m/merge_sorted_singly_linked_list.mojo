from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("merge_sorted_singly_linked_list")
fn merge_sorted_singly_linked_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130:
        return -1
    if input[0] < 0 or input[0] > 128:
        return -1
    let a_count = Int(input[0])
    if a_count > Int(length) - 2:
        return -1
    let b_count_raw = input[1 + a_count]
    if b_count_raw < 0 or b_count_raw > Int64(128 - a_count):
        return -1
    let b_count = Int(b_count_raw)
    let total = a_count + b_count
    if Int(length) != total + 2:
        return -1
    var values = InlineArray[Int64, 128](fill=0)
    var links = InlineArray[Int, 128](fill=-1)
    for i in range(a_count):
        let value = input[1 + i]
        if value < -2147483648 or value > 2147483647:
            return -1
        if i > 0 and input[i] > value:
            return -1
        values[i] = value
        if i + 1 < a_count:
            links[i] = i + 1
    let b_start = a_count + 2
    for i in range(b_count):
        let value = input[b_start + i]
        if value < -2147483648 or value > 2147483647:
            return -1
        if i > 0 and input[b_start + i - 1] > value:
            return -1
        values[a_count + i] = value
        if i + 1 < b_count:
            links[a_count + i] = a_count + i + 1
    var a = -1
    var b = -1
    if a_count > 0: a = 0
    if b_count > 0: b = a_count
    var head = -1
    var tail = -1
    while a >= 0 and b >= 0:
        var chosen = 0
        if values[a] <= values[b]:
            chosen = a
            a = links[a]
        else:
            chosen = b
            b = links[b]
        if tail < 0:
            head = chosen
        else:
            links[tail] = chosen
        tail = chosen
    var remaining = b
    if a >= 0: remaining = a
    if tail < 0:
        head = remaining
    else:
        links[tail] = remaining
    let byte_count = 12 * total
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    var node = head
    var offset = 0
    while node >= 0:
        var origin: Int64 = 0
        var position = Int64(node)
        if node >= a_count:
            origin = 1
            position = Int64(node - a_count)
        for byte in range(4):
            output[offset + byte] = UInt8((values[node] >> (8 * byte)) & 255)
            output[offset + 4 + byte] = UInt8((origin >> (8 * byte)) & 255)
            output[offset + 8 + byte] = UInt8((position >> (8 * byte)) & 255)
        offset += 12
        node = links[node]
    return Int64(byte_count)
