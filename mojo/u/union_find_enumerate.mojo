from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_ITEMS = 16
const MAX_OPERATIONS = 32
const MAX_INPUT_LENGTH = 99

fn ufe_find(mut parent: InlineArray[Int64, 16], item: Int) -> Int:
    var root = item
    while parent[root] >= 0: root = Int(parent[root])
    var current = item
    while current != root:
        let next_item = Int(parent[current])
        parent[current] = Int64(root)
        current = next_item
    return root

fn ufe_component_mask(successor: InlineArray[Int64, 16], start: Int) -> Int64:
    var mask: UInt64 = 0
    var item = start
    while True:
        mask |= UInt64(1) << item
        item = Int(successor[item])
        if item == start: break
    return Int64(mask)

@export("union_find_enumerate")
fn union_find_enumerate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let item_count_value = input[0]
    let operation_count_value = input[1]
    if item_count_value < 1 or item_count_value > MAX_ITEMS or operation_count_value < 0 or operation_count_value > MAX_OPERATIONS: return -1
    let item_count = Int(item_count_value)
    let operation_count = Int(operation_count_value)
    if length != c_size_t(2 + 3 * operation_count): return -1

    for operation in range(operation_count):
        let position = 2 + 3 * operation
        let opcode = input[position]
        let first = input[position + 1]
        let second = input[position + 2]
        if opcode == 0:
            if first < 0 or first >= item_count_value or second < 0 or second >= item_count_value: return -1
        elif opcode == 1:
            if first < 0 or first >= item_count_value or second != 0: return -1
        else:
            return -1

    var parent = InlineArray[Int64, 16](fill=-1)
    var successor = InlineArray[Int64, 16](fill=0)
    for item in range(item_count): successor[item] = Int64(item)
    var checksum: Int64 = 0
    for operation in range(operation_count):
        let position = 2 + 3 * operation
        let opcode = input[position]
        let first = Int(input[position + 1])
        var observed: Int64 = 0
        if opcode == 0:
            var left = ufe_find(parent, first)
            var right = ufe_find(parent, Int(input[position + 2]))
            if left != right:
                if parent[left] > parent[right]:
                    let temporary = left
                    left = right
                    right = temporary
                parent[left] += parent[right]
                parent[right] = Int64(left)
                let temporary_next = successor[left]
                successor[left] = successor[right]
                successor[right] = temporary_next
                observed = 1
        else:
            observed = ufe_component_mask(successor, first)
        checksum += Int64(operation + 1) * (observed + 1)
    return checksum
