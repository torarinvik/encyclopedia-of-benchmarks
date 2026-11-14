from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

# Independent bounded truth-table evaluator; see the package's AFPL v5 notice.
@export("cbench_ghostscript_rop3")
fn cbench_ghostscript_rop3(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length != 4 or values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    for i in range(3):
        if values[i] < 0 or values[i] > 4294967295: return -1
    let code = values[3]
    if code < 0 or code > 255: return -1
    var result = Int64(0)
    for bit in range(32):
        let d = (values[0] >> bit) & 1
        let s = (values[1] >> bit) & 1
        let t = (values[2] >> bit) & 1
        let index = Int(d | (s << 1) | (t << 2))
        result |= ((code >> index) & 1) << bit
    return result
