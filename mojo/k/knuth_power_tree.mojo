from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn kpt_build(target: Int, inout parent: InlineArray[Int, 128],
    inout seen: InlineArray[Bool, 128], inout queue: InlineArray[Int, 128],
    inout reverse: InlineArray[Int, 128], inout path: InlineArray[Int, 127],
    inout path_length: Int) -> Bool:
    if target == 1:
        path[0] = 1
        path_length = 1
        return True
    var head = 0
    var tail = 1
    queue[0] = 1
    seen[1] = True
    while head < tail:
        let current = queue[head]
        head += 1
        var chain_length = 0
        var node = current
        while node != 0:
            reverse[chain_length] = node
            chain_length += 1
            node = parent[node]
        for offset in range(chain_length):
            let ancestor = reverse[chain_length - offset - 1]
            let child = current + ancestor
            if child > target or seen[child]:
                continue
            seen[child] = True
            parent[child] = current
            if child == target:
                var count = 0
                node = target
                while node != 0:
                    path[count] = node
                    count += 1
                    node = parent[node]
                var left = 0
                var right = count - 1
                while left < right:
                    let temporary = path[left]
                    path[left] = path[right]
                    path[right] = temporary
                    left += 1
                    right -= 1
                path_length = count
                return True
            queue[tail] = child
            tail += 1
    return False

fn kpt_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("knuth_power_tree")
fn knuth_power_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let target_value = input[0]
    if target_value < 1 or target_value > 127: return -1
    let target = Int(target_value)
    var parent = InlineArray[Int, 128](fill=0)
    var seen = InlineArray[Bool, 128](fill=False)
    var queue = InlineArray[Int, 128](fill=0)
    var reverse = InlineArray[Int, 128](fill=0)
    var path = InlineArray[Int, 127](fill=0)
    var path_length = 0
    if not kpt_build(target, parent, seen, queue, reverse, path, path_length): return -1
    let required = (path_length + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    kpt_store_i64(output, 0, Int64(path_length - 1))
    for index in range(path_length): kpt_store_i64(output, 8 * (index + 1), Int64(path[index]))
    return Int64(required)
