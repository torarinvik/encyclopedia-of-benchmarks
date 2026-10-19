from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAX_UINT53: Int64 = 9007199254740991
@export("uint53_ones_count")
fn uint53_ones_count(value: Int64) abi("C") -> Int64:
    if value < 0 or value > MAX_UINT53: return -1
    var total: Int64 = 0
    var rest = value
    for _ in range(7):
        var byte = rest % 256
        var count: Int64 = 0
        for _ in range(8): count += byte % 2; byte /= 2
        total += count
        rest /= 256
    return total
