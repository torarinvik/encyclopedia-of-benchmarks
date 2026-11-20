from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_LIMIT = 1024
alias LINK_COUNT = 1026

@export("sieve_of_pritchard")
fn sieve_of_pritchard(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2:
        return -1
    if length != 1 or input[0] < 2 or input[0] > MAX_LIMIT:
        return -1

    let limit = Int32(input[0])
    let sentinel = limit + 1
    var next_node = InlineArray[Int32, LINK_COUNT]()
    var previous = InlineArray[Int32, LINK_COUNT]()
    next_node[1] = sentinel
    next_node[Int(sentinel)] = sentinel
    previous[Int(sentinel)] = 1
    var wheel_length: Int32 = 2
    var prime: Int32 = 3
    var prime_count: Int64 = 1

    while prime * prime <= limit:
        if wheel_length < limit:
            let product = prime * wheel_length
            let target = product if product < limit else limit
            var wheel_value: Int32 = 1
            var candidate = wheel_length + 1
            while candidate <= target:
                let tail = previous[Int(sentinel)]
                next_node[Int(tail)] = candidate
                previous[Int(candidate)] = tail
                next_node[Int(candidate)] = sentinel
                previous[Int(sentinel)] = candidate
                wheel_value = next_node[Int(wheel_value)]
                candidate = wheel_length + wheel_value
            wheel_length = target

        var wheel_value = prime
        while prime * wheel_value <= wheel_length:
            wheel_value = next_node[Int(wheel_value)]
        while wheel_value > 1:
            wheel_value = previous[Int(wheel_value)]
            let removed = prime * wheel_value
            let left = previous[Int(removed)]
            let right = next_node[Int(removed)]
            next_node[Int(left)] = right
            previous[Int(right)] = left
        prime_count += 1
        prime = next_node[1]

    if wheel_length < limit:
        var wheel_value: Int32 = 1
        var candidate = wheel_length + 1
        while candidate <= limit:
            let tail = previous[Int(sentinel)]
            next_node[Int(tail)] = candidate
            previous[Int(candidate)] = tail
            next_node[Int(candidate)] = sentinel
            previous[Int(sentinel)] = candidate
            wheel_value = next_node[Int(wheel_value)]
            candidate = wheel_length + wheel_value
        wheel_length = limit

    var remaining: Int64 = 0
    var value = next_node[1]
    while value != sentinel:
        remaining += 1
        value = next_node[Int(value)]
    return prime_count + remaining
