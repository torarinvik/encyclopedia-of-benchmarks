from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

# Independent bounded predicate; see the package's AFPL v5 notice.
@export("cbench_ghostscript_rop3_idempotence")
fn cbench_ghostscript_rop3_idempotence(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length != 1 or values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    let code = values[0]
    if code < 0 or code > 255: return -1
    for pair in range(4):
        let low = (code >> (2 * pair)) & 1
        let high = (code >> (2 * pair + 1)) & 1
        if high == 1 and low == 0: return 0
    return 1
