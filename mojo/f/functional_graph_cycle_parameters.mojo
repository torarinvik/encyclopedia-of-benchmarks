from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias ENCODING_BASE = 65

fn next_node(input: UnsafePointer[Int64, ImmutAnyOrigin], node: Int64) -> Int64:
    input[2 + node]

@export("functional_graph_cycle_parameters")
fn functional_graph_cycle_parameters(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_N + 2):
        return -1
    let n = input[0]
    let start = input[1]
    if n < 1 or n > MAX_N or start < 0 or start >= n or length != c_size_t(n + 2):
        return -1
    for i in range(n):
        let successor = input[2 + i]
        if successor < 0 or successor >= n:
            return -1

    var tortoise = next_node(input, start)
    var hare = next_node(input, next_node(input, start))
    while tortoise != hare:
        tortoise = next_node(input, tortoise)
        hare = next_node(input, next_node(input, hare))

    var mu: Int64 = 0
    tortoise = start
    while tortoise != hare:
        tortoise = next_node(input, tortoise)
        hare = next_node(input, hare)
        mu += 1

    var lambda: Int64 = 1
    hare = next_node(input, tortoise)
    while hare != tortoise:
        hare = next_node(input, hare)
        lambda += 1
    return ENCODING_BASE * mu + lambda
