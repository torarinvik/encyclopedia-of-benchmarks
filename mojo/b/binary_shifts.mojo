from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bits_u32(value_in: UInt32) -> List[UInt8]:
    var value = value_in; var reversed = List[UInt8](capacity=32)
    while True:
        reversed.append(UInt8(48 + (value & 1))); value >>= 1
        if value == 0: break
    var result = List[UInt8](capacity=len(reversed))
    for i in range(len(reversed) - 1, -1, -1): result.append(reversed[i])
    return result

@export("binary_shifts")
fn binary_shifts(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let op = input[0]; let number = input[1]; let shiftv = input[2]
    if op < 0 or op > 2 or number < -2_147_483_647 or number > 2_147_483_647 or shiftv < 0 or shiftv > 31 or (op < 2 and number < 0): return -1
    let shift = Int(shiftv); var bits = List[UInt8](capacity=40)
    if op == 0 or op == 1:
        bits = bits_u32(UInt32(number))
    elif number >= 0:
        bits.append(48); let normal = bits_u32(UInt32(number))
        for b in normal: bits.append(b)
    else:
        let magnitude = UInt32(-number); let mag_bits = bits_u32(magnitude); let width = len(mag_bits)
        let complement = (UInt32(1) << width) - magnitude
        let complement_bits = bits_u32(complement)
        bits.append(49)
        for _ in range(len(complement_bits), width): bits.append(48)
        for b in complement_bits: bits.append(b)
    var result = List[UInt8](capacity=80); result.append(48); result.append(98)
    if op == 0:
        for b in bits: result.append(b)
        for _ in range(shift): result.append(48)
    elif op == 1:
        if shift >= len(bits): result.append(48)
        else:
            for i in range(len(bits) - shift): result.append(bits[i])
    else:
        let sign = bits[0]
        if shift >= len(bits):
            for _ in range(len(bits)): result.append(sign)
        else:
            for _ in range(shift): result.append(sign)
            for i in range(len(bits) - shift): result.append(bits[i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(result)): return -2
    for i in range(len(result)): output[i] = result[i]
    return Int64(len(result))
