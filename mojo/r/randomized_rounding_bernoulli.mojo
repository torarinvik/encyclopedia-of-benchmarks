from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("randomized_rounding_bernoulli")
fn randomized_rounding_bernoulli(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 65: return -1
    let count = input[0]
    if count < 1 or count > 16 or length != c_size_t(1 + 4 * count): return -1
    let n = Int(count)
    var decisions = InlineArray[UInt8, 16](fill=0)
    for i in range(n):
        let xn = input[1 + 4 * i]
        let xd = input[2 + 4 * i]
        let un = input[3 + 4 * i]
        let ud = input[4 + 4 * i]
        if xd < 1 or xd > 32 or xn < 0 or xn > xd or ud < 1 or ud > 32 or un < 0 or un >= ud: return -1
        if un * xd < xn * ud: decisions[i] = 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    for i in range(n): output[i] = decisions[i]
    return Int64(n)
