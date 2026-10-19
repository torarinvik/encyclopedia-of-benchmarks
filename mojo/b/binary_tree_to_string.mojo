from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_NODES = 127

fn append_decimal(value: Int64, mut bytes: List[UInt8]) -> None:
    var magnitude = value
    if magnitude < 0:
        bytes.append(UInt8(45))
        magnitude = -magnitude
    var digits = List[UInt8](capacity=10)
    while True:
        digits.append(UInt8(48 + magnitude % 10))
        magnitude = magnitude // 10
        if magnitude == 0: break
    for i in range(len(digits)):
        bytes.append(digits[len(digits) - 1 - i])

fn emit_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], node: Int, mut bytes: List[UInt8]) -> None:
    let base = 2 + 3 * node
    let left = input[base + 1]
    let right = input[base + 2]
    append_decimal(input[base], bytes)
    if left >= 0:
        bytes.append(UInt8(40))
        emit_tree(input, Int(left), bytes)
        bytes.append(UInt8(41))
    elif right >= 0:
        bytes.append(UInt8(40)); bytes.append(UInt8(41))
    if right >= 0:
        bytes.append(UInt8(40))
        emit_tree(input, Int(right), bytes)
        bytes.append(UInt8(41))

@export("binary_tree_to_string")
fn binary_tree_to_string(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let nv = input[0]
    if nv < 0 or nv > MAX_NODES or length != c_size_t(2 + 3 * nv): return -1
    let n = Int(nv); let root = input[1]
    if n == 0: return 0 if root == -1 else -1
    if root < 0 or root >= nv: return -1
    var parents = List[Int](capacity=n)
    var seen = List[Bool](capacity=n)
    for _ in range(n): parents.append(0); seen.append(False)
    for i in range(n):
        let base = 2 + 3 * i
        let value = input[base]; let left = input[base + 1]; let right = input[base + 2]
        if value < -2_147_483_648 or value > 2_147_483_647 or left < -1 or right < -1 or left >= nv or right >= nv: return -1
        if left >= 0:
            parents[Int(left)] += 1
            if parents[Int(left)] > 1: return -1
        if right >= 0:
            parents[Int(right)] += 1
            if parents[Int(right)] > 1: return -1
    for i in range(n):
        if parents[i] != (0 if i == Int(root) else 1): return -1
    var stack = List[Int](capacity=n); stack.append(Int(root))
    var visited = 0
    while len(stack) > 0:
        let node = stack.pop()
        if seen[node]: return -1
        seen[node] = True; visited += 1
        let base = 2 + 3 * node
        if input[base + 1] >= 0: stack.append(Int(input[base + 1]))
        if input[base + 2] >= 0: stack.append(Int(input[base + 2]))
    if visited != n: return -1
    var bytes = List[UInt8](capacity=16 * n)
    emit_tree(input, Int(root), bytes)
    if len(bytes) == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
