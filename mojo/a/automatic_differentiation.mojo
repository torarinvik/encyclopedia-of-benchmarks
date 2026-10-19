from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import abs

fn autodiff_power(x: Float64, exponent: Int) -> Float64:
    var value: Float64 = 1.0
    for _ in range(exponent): value *= x
    return value

@export("automatic_differentiation")
fn automatic_differentiation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8: return -1.0e300
    let leaves = input[0]
    let ops = input[1]
    let target = input[2]
    let source = input[3]
    if leaves < 1 or leaves > 32 or ops < 1 or ops > 64 or length != c_size_t(4 + leaves + 3 * ops): return -1.0e300
    let nodes_n = Int(leaves + ops)
    if target < leaves or target >= Int64(nodes_n) or source < 0 or source >= leaves: return -1.0e300
    var nodes = List[Float64](length=96, fill=0.0)
    for i in range(Int(leaves)):
        if input[4 + i] < -16 or input[4 + i] > 16: return -1.0e300
        nodes[i] = Float64(input[4 + i])
    var opcodes = List[Int64](length=64, fill=0)
    var lefts = List[Int](length=64, fill=0)
    var rights = List[Int](length=64, fill=0)
    var offset = 4 + Int(leaves)
    for op in range(Int(ops)):
        let opcode = input[offset]
        let left = input[offset + 1]
        let right = input[offset + 2]
        let out = Int(leaves) + op
        if left < 0 or left >= Int64(out): return -1.0e300
        var result: Float64 = 0.0
        if opcode == 5:
            if right < 1 or right > 8: return -1.0e300
            result = autodiff_power(nodes[Int(left)], Int(right))
        else:
            if opcode < 0 or opcode > 3 or right < 0 or right >= Int64(out): return -1.0e300
            let r = nodes[Int(right)]
            if opcode == 0: result = nodes[Int(left)] + r
            elif opcode == 1: result = nodes[Int(left)] - r
            elif opcode == 2: result = nodes[Int(left)] * r
            else:
                if r == 0.0: return -1.0e300
                result = nodes[Int(left)] / r
        if result != result or abs(result) > 1.0e10: return -1.0e300
        nodes[out] = result
        opcodes[op] = opcode
        lefts[op] = Int(left)
        rights[op] = Int(right)
        offset += 3
    var adjoints = List[Float64](length=96, fill=0.0)
    var ancestors = List[Int](length=96, fill=0)
    adjoints[Int(target)] = 1.0
    ancestors[Int(target)] = 1
    let last_op = Int(target - leaves)
    for cursor in range(last_op, -1, -1):
        let out = Int(leaves) + cursor
        if ancestors[out] == 0: continue
        let opcode = opcodes[cursor]
        let left = lefts[cursor]
        let right = rights[cursor]
        let adj = adjoints[out]
        ancestors[left] = 1
        if opcode == 5:
            adjoints[left] += Float64(right) * autodiff_power(nodes[left], Int(right) - 1) * adj
        else:
            ancestors[right] = 1
            if opcode == 0:
                adjoints[left] += adj; adjoints[right] += adj
            elif opcode == 1:
                adjoints[left] += adj; adjoints[right] -= adj
            elif opcode == 2:
                adjoints[left] += nodes[right] * adj; adjoints[right] += nodes[left] * adj
            else:
                adjoints[left] += (1.0 / nodes[right]) * adj
                adjoints[right] += (-nodes[left] / (nodes[right] * nodes[right])) * adj
    if ancestors[Int(source)] == 0 or adjoints[Int(source)] != adjoints[Int(source)] or abs(adjoints[Int(source)]) > 1.0e300: return -1.0e300
    return adjoints[Int(source)]
