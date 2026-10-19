from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime INVALID: Int64 = -2_147_483_649

@export("bit_swap")
fn bit_swap(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return INVALID
    let data = input[0]; let a = input[1]; let b = input[2]
    if data < -2_147_483_648 or data > 2_147_483_647 or a < 0 or a > 31 or b < 0 or b > 31: return INVALID
    var word = UInt32(data if data >= 0 else data + 4_294_967_296)
    if ((word >> Int(a)) & 1) != ((word >> Int(b)) & 1):
        word = word ^ ((UInt32(1) << Int(a)) | (UInt32(1) << Int(b)))
    if word >= UInt32(2_147_483_648): return Int64(word) - 4_294_967_296
    return Int64(word)
