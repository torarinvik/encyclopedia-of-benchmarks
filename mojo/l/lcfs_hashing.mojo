from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_CAPACITY = 32
const MAX_KEY: Int64 = 1_000_000

@export("lcfs_hashing")
fn lcfs_hashing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 35: return -1
    let capacity_value = input[0]
    let count_value = input[1]
    if capacity_value < 1 or capacity_value > MAX_CAPACITY or count_value < 0 or count_value > capacity_value: return -1
    if length != c_size_t(count_value + 2): return -1
    let capacity = Int(capacity_value)
    let count = Int(count_value)
    for i in range(count):
        let key = input[i + 2]
        if key < 0 or key > MAX_KEY: return -1
        for j in range(i):
            if input[j + 2] == key: return -1

    var table = InlineArray[Int64, 32](fill=-1)
    var displacements: Int64 = 0
    for i in range(count):
        var incoming = input[i + 2]
        var slot = Int(incoming % capacity_value)
        var probes = 0
        while table[slot] != -1:
            if probes >= capacity: return -1
            let resident = table[slot]
            table[slot] = incoming
            incoming = resident
            slot = (slot + 1) % capacity
            probes += 1
            displacements += 1
        table[slot] = incoming
    return displacements
