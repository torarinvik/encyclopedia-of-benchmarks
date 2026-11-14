from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn key_ge(a: UInt64, b: UInt64) -> Bool:
    let exp_a = (a >> 23) & 255; let exp_b = (b >> 23) & 255
    let frac_a = a & 0x7fffff; let frac_b = b & 0x7fffff
    if (exp_a == 255 and frac_a != 0) or (exp_b == 255 and frac_b != 0): return False
    let mag_a = a & 0x7fffffff; let mag_b = b & 0x7fffffff
    if mag_a == 0 and mag_b == 0: return True
    let neg_a = (a >> 31) != 0; let neg_b = (b >> 31) != 0
    if neg_a != neg_b: return not neg_a
    if neg_a: return mag_a <= mag_b
    return mag_a >= mag_b

@export("versabench_dbms_valid_index_key")
fn versabench_dbms_valid_index_key(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 8: return -1
    var bits = InlineArray[UInt64, 8](fill=0)
    for i in range(8):
        let value = input[i]
        if value < 0 or value > 4294967295: return -1
        bits[i] = UInt64(value)
    for i in range(4):
        if key_ge(bits[i], bits[i + 4]): return 0
    return 1
