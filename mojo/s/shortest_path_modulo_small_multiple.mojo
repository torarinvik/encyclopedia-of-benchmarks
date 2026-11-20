from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn minimum_digit_sum(n: Int64) -> Int64:
    var distance = InlineArray[Int64, 16]()
    var deque = InlineArray[Int32, 512]()
    for i in range(Int(n)):
        distance[i] = 1000
    var head = 0
    var tail = 0
    var queued = 0
    let start = Int(1 % n)
    distance[start] = 1
    deque[tail] = Int32(start)
    tail = (tail + 1) % 512
    queued += 1
    while queued > 0:
        let residue = Int(deque[head])
        head = (head + 1) % 512
        queued -= 1
        let zero_next = Int((Int64(residue) * 10) % n)
        if distance[zero_next] > distance[residue]:
            distance[zero_next] = distance[residue]
            head = (head + 511) % 512
            deque[head] = Int32(zero_next)
            queued += 1
        let one_next = Int((Int64(zero_next) + 1) % n)
        if distance[one_next] > distance[residue] + 1:
            distance[one_next] = distance[residue] + 1
            deque[tail] = Int32(one_next)
            tail = (tail + 1) % 512
            queued += 1
    return distance[0]

@export("shortest_path_modulo_small_multiple")
fn shortest_path_modulo_small_multiple(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let n = input[0]
    if n < 1 or n > 16: return -1
    return minimum_digit_sum(n)
