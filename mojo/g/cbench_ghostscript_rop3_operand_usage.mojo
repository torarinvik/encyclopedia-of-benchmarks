from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

# Independent truth-table dependency test; see the bundled AFPL v5 notice.
@export("cbench_ghostscript_rop3_operand_usage")
fn cbench_ghostscript_rop3_operand_usage(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if length != 1 or values == UnsafePointer[Int64, ImmutAnyOrigin]():
        return -1
    let code = values[0]
    if code < 0 or code > 255:
        return -1
    var result = Int64(0)
    for dimension in range(3):
        let toggle = 1 << dimension
        for index in range(8):
            if (index & toggle) == 0:
                let first = (code >> index) & 1
                let second = (code >> (index | toggle)) & 1
                if first != second:
                    result |= Int64(toggle)
                    break
    return result
