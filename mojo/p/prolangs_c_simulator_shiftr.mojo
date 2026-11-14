# (c) William Landi 1991. See package LICENSE.txt for the permission notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("prolangs_c_simulator_shiftr")
fn prolangs_c_simulator_shiftr(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let operand = input[0]
    let value = input[1]
    if operand < 0 or operand > 255 or (operand >> 4) >= 10 or value < 0 or value > 0xffffff:
        return -1
    let shift = Int((operand & 15) + 1)
    var result = value >> shift
    if (value & 0x800000) != 0:
        result |= ((Int64(1) << shift) - 1) << (24 - shift)
    return result & 0xffffff
