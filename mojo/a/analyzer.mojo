from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("analyzer")
fn analyzer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 193: return -1
    let count0 = input[0]
    if count0 < 0 or count0 > 64 or length != c_size_t(1 + 3 * count0): return -1
    let count = Int(count0)
    var latest = List[Int](length=256, fill=-1)
    var previous_epoch: Int64 = 0
    var conflicts: Int64 = 0
    for event in range(count):
        let base = 1 + 3 * event
        let epoch = input[base]
        let opcode = input[base + 1]
        let address = input[base + 2]
        if epoch < previous_epoch or epoch > 15 or (opcode != 0 and opcode != 1) or address < 0 or address > 255: return -1
        previous_epoch = epoch
        if opcode == 0:
            latest[Int(address)] = event
        else:
            for prior in range(event):
                let prior_base = 1 + 3 * prior
                if input[prior_base] < epoch and input[prior_base + 1] == 0 and input[prior_base + 2] == address and latest[Int(address)] == prior:
                    conflicts += 1
    return conflicts
