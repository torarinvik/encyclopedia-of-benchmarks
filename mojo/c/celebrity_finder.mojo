from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("celebrity_finder")
fn celebrity_finder(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 1 or input[0] > 64: return -2
    let n = input[0]
    if length != 1 + n * n: return -2
    for i in range(1, length):
        if input[i] != 0 and input[i] != 1: return -2
    var stack = InlineArray[Int64, 64](0)
    var top: Int64 = 0
    for i in range(n):
        stack[top] = i
        top += 1
    while top > 1:
        top -= 1
        let person1 = stack[top]
        top -= 1
        let person2 = stack[top]
        stack[top] = person2 if input[1 + person1 * n + person2] == 1 else person1
        top += 1
    let candidate = stack[0]
    for i in range(n):
        if i == candidate: continue
        if input[1 + candidate * n + i] == 1 or input[1 + i * n + candidate] == 0: return -1
    return candidate
