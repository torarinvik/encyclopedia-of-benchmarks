from std.sys.intrinsics import llvm_intrinsic

@export("count_leading_zeros")
def count_leading_zeros(value: Int64) abi("C") -> Int64:
    if value < -2147483648 or value > 2147483647:
        return -1
    return Int64(llvm_intrinsic["llvm.ctlz.i32", Int32](Int32(value), False))
