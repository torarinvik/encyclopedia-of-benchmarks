from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_PARSEABLE = 66

fn comes_before(input: UnsafePointer[Int64, ImmutAnyOrigin], left: Int,
                right: Int, descending: Bool) -> Bool:
    let left_value = input[left + 1]
    let right_value = input[right + 1]
    if left_value != right_value:
        return left_value > right_value if descending else left_value < right_value
    return left < right

fn build_successors(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
                    descending: Bool, target: UnsafePointer[Int64, MutAnyOrigin]):
    var order = InlineArray[Int, MAX_N](fill=0)
    var stack = InlineArray[Int, MAX_N](fill=0)
    for i in range(n):
        order[i] = i
        target[i] = -1
    for i in range(1, n):
        let key = order[i]
        var position = i
        while position > 0 and comes_before(input, key, order[position - 1], descending):
            order[position] = order[position - 1]
            position -= 1
        order[position] = key
    var stack_size = 0
    for i in range(n):
        let index = order[i]
        while stack_size > 0 and stack[stack_size - 1] < index:
            stack_size -= 1
            target[stack[stack_size]] = Int64(index)
        stack[stack_size] = index
        stack_size += 1

@export("odd_even_jump_reachability_count")
fn odd_even_jump_reachability_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_PARSEABLE):
        return -1
    if input[0] < 1 or input[0] > MAX_N: return -1
    let n = Int(input[0])
    if length != c_size_t(n + 1): return -1
    for i in range(n):
        if input[i + 1] < -1000000 or input[i + 1] > 1000000: return -1

    var odd_next = InlineArray[Int64, MAX_N](fill=-1)
    var even_next = InlineArray[Int64, MAX_N](fill=-1)
    build_successors(input, n, False, odd_next.unsafe_ptr())
    build_successors(input, n, True, even_next.unsafe_ptr())
    var odd = InlineArray[UInt8, MAX_N](fill=0)
    var even = InlineArray[UInt8, MAX_N](fill=0)
    odd[n - 1] = 1
    even[n - 1] = 1
    var index = n - 1
    while index > 0:
        index -= 1
        if odd_next[index] >= 0: odd[index] = even[Int(odd_next[index])]
        if even_next[index] >= 0: even[index] = odd[Int(even_next[index])]
    var count: Int64 = 0
    for i in range(n):
        if odd[i] != 0: count += 1
    return count
