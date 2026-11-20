from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VALUES = 256
comptime MAX_INPUT_LENGTH = 258

fn distinguished_ancestor(node_input: Int,
        inout reverse: InlineArray[Bool, MAX_VALUES]) -> Int:
    var node = node_input
    while (node % 2 == 1) == reverse[node / 2]:
        node /= 2
    return node / 2

fn weak_join(inout values: InlineArray[Int64, MAX_VALUES],
        inout reverse: InlineArray[Bool, MAX_VALUES], ancestor: Int, node: Int):
    if values[ancestor] < values[node]:
        let temporary = values[ancestor]
        values[ancestor] = values[node]
        values[node] = temporary
        reverse[node] = not reverse[node]

fn sift_down(active_size: Int, inout values: InlineArray[Int64, MAX_VALUES],
        inout reverse: InlineArray[Bool, MAX_VALUES]):
    var node = 1
    if reverse[0]:
        node = 0
    if node >= active_size:
        return
    while True:
        var child = 2 * node
        if reverse[node]:
            child += 1
        if child >= active_size:
            break
        node = child
    while node != 0:
        weak_join(inout values, inout reverse, 0, node)
        node /= 2

@export("weak_heapsort")
fn weak_heapsort(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > MAX_VALUES:
        return -1
    let count = Int(raw_count)
    if length != c_size_t(count + 1):
        return -1

    var values = InlineArray[Int64, MAX_VALUES](fill=0)
    var reverse = InlineArray[Bool, MAX_VALUES](fill=False)
    for index in range(count):
        let value = input[index + 1]
        if value < -1000 or value > 1000:
            return -1
        values[index] = value

    var next = count
    while next > 1:
        next -= 1
        let node = next
        let ancestor = distinguished_ancestor(node, inout reverse)
        weak_join(inout values, inout reverse, ancestor, node)

    var end = count
    while end > 1:
        let temporary = values[0]
        values[0] = values[end - 1]
        values[end - 1] = temporary
        end -= 1
        sift_down(end, inout values, inout reverse)

    var checksum: Int64 = 0
    for index in range(count):
        checksum += Int64(index + 1) * (values[index] + 1001)
    return checksum
