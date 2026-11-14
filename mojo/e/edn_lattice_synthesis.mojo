# Independent implementation of the bounded lattice recurrence; see package NOTICE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("edn_lattice_synthesis")
fn edn_lattice_synthesis(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 34: return -1
    let order0 = input[0]
    var f = input[1]
    if order0 < 1 or order0 > 16 or f < -65536 or f > 65535 or length != c_size_t(2 + 2 * order0): return -1
    let order = Int(order0)
    for i in range(2, 2 + 2 * order):
        if input[i] < -1024 or input[i] > 1023: return -1
    let bytes = 8 * (order + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var state = List[Int64](length=order, fill=0)
    for i in range(order): state[i] = input[2 + i]
    f -= state[order - 1] * input[2 + 2 * order - 1]
    var i = order - 1
    while i > 0:
        i -= 1
        let coefficient = input[2 + order + i]
        f -= state[i] * coefficient
        state[i + 1] = state[i] + ((coefficient * (f >> 16)) >> 16)
    state[0] = f >> 16
    for word in range(order + 1):
        var value = f
        if word > 0: value = state[word - 1]
        for byte in range(8): output[8 * word + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
