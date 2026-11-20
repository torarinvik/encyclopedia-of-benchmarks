from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 64
const MAX_VALUE: Int64 = 255
const ABSENT_CODE: Int64 = 64
const PACK_BASE: Int64 = 65

@export("bond_sequential_search")
fn bond_sequential_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 68: return -1
    let count_value = input[0]
    let key_a = input[1]
    let key_b = input[2]
    if count_value < 0 or count_value > MAX_N or length != c_size_t(count_value + 3): return -1
    if key_a < 0 or key_a > MAX_VALUE or key_b < 0 or key_b > MAX_VALUE or key_a == key_b: return -1

    let count = Int(count_value)
    for i in range(count):
        let value = input[i + 3]
        if value < 0 or value > MAX_VALUE: return -1

    var index_a = ABSENT_CODE
    var index_b = ABSENT_CODE
    let composite = key_a | key_b
    for i in range(count):
        if index_a != ABSENT_CODE and index_b != ABSENT_CODE: break
        let value = input[i + 3]
        if (value & composite) != value: continue
        if index_a == ABSENT_CODE and value == key_a: index_a = Int64(i)
        if index_b == ABSENT_CODE and value == key_b: index_b = Int64(i)
    return index_a * PACK_BASE + index_b
