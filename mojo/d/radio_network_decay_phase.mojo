from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("radio_network_decay_phase")
fn radio_network_decay_phase(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 75: return -1
    let nv = input[0]; let kv = input[1]; let initial = input[2]
    if nv < 2 or nv > 8 or kv < 1 or kv > 8 or length != c_size_t(3 + nv + nv * kv): return -1
    let n = Int(nv); let k = Int(kv); let full = (Int64(1) << n) - 1
    if initial <= 0 or (initial & ~full) != 0: return -1
    var adjacency = InlineArray[Int64, 8](fill=0)
    var tape = InlineArray[Int64, 64](fill=0)
    for v in range(n):
        let mask = input[3 + v]
        if mask < 0 or (mask & ~full) != 0 or (mask & (Int64(1) << v)) != 0: return -1
        adjacency[v] = mask
    for u in range(n):
        for v in range(n):
            if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1): return -1
    for i in range(n * k):
        let value = input[3 + n + i]
        if value != 0 and value != 1: return -1
        tape[i] = value
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var active = initial
    var newly: Int64 = 0
    var transmissions: Int64 = 0
    for slot in range(k):
        for sender in range(n):
            if (active & (Int64(1) << sender)) != 0: transmissions += 1
        for receiver in range(n):
            if (initial & (Int64(1) << receiver)) == 0:
                var senders = 0
                for sender in range(n):
                    if (active & (Int64(1) << sender)) != 0 and (adjacency[sender] & (Int64(1) << receiver)) != 0: senders += 1
                if senders == 1: newly |= Int64(1) << receiver
        for sender in range(n):
            if (active & (Int64(1) << sender)) != 0 and (tape[sender * k + slot] == 0 or slot + 1 == k):
                active &= ~(Int64(1) << sender)
    for slot in range(2):
        var bits = UInt64(newly if slot == 0 else transmissions)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return 16
