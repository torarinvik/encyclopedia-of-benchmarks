# (c) William Landi 1991. See package LICENSE.txt for the permission notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("prolangs_c_simulator_format3_4")
fn prolangs_c_simulator_format3_4(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 7: return -1
    let pc = input[0]
    let x = input[1]
    let b = input[2]
    if pc < 0 or pc > 1048572 or x < 0 or x >= 16777216 or b < 0 or b >= 16777216: return -1
    var bytes = InlineArray[Int64, 4](fill=0)
    for i in range(4):
        let value = input[3 + i]
        if value < 0 or value > 255: return -1
        bytes[i] = value
    let nf = (bytes[0] >> 1) & 1
    let immediate = bytes[0] & 1
    let indexed = (bytes[1] >> 7) & 1
    let base = (bytes[1] >> 6) & 1
    let relative = (bytes[1] >> 5) & 1
    let extended = (bytes[1] >> 4) & 1
    let sic = nf == 0 and immediate == 0
    let format: Int64 = if extended == 1 and not sic: 4 else: 3
    var address: Int64 = 0
    if format == 4:
        if base != 0 or relative != 0: return -1
        address = ((bytes[1] & 15) << 16) | (bytes[2] << 8) | bytes[3]
        if indexed != 0: address += x
    else:
        address = ((bytes[1] & 15) << 8) | bytes[2]
        if sic: return 0
        if base != 0 and relative != 0: return -1
        if indexed != 0: address += x
        if base != 0: address += b
        if relative != 0:
            if address >= 2048: address = address - 4096 + pc + format
            else: address += pc + format
    if nf == 1 and immediate == 0: return -1
    if address < 0 or (nf == 0 and immediate == 1 and address >= 16777216): return -1
    return address
