from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn manacher_alnum(x: Int64) -> Bool:
    return (x >= 48 and x <= 57) or (x >= 65 and x <= 90) or (x >= 97 and x <= 122)

fn manacher_equal(v: UnsafePointer[Int64, ImmutAnyOrigin], left: Int, right: Int) -> Bool:
    if left % 2 != right % 2: return False
    return left % 2 == 0 or v[left / 2] == v[right / 2]

@export("manacher")
fn manacher(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n == 0 or n > 1000: return -1
    for i in range(Int(n)):
        if not manacher_alnum(v[i]): return -1
    let m = 2 * Int(n) + 1
    var radii = InlineArray[Int, 2001](fill=0)
    var center = 0; var right = 0; var best_center = 0; var best_radius = 0
    for i in range(m):
        var radius = 0
        if i < right:
            let mirror = 2 * center - i
            radius = radii[mirror] if radii[mirror] < right-i else right-i
        while radius < i and radius < m-1-i and manacher_equal(v, i-radius-1, i+radius+1): radius += 1
        radii[i] = radius
        if i + radius > right: center = i; right = i + radius
        if radius > best_radius: best_center = i; best_radius = radius
    let start = (best_center - best_radius) / 2
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(best_radius): return -2
    for i in range(best_radius): out[i] = UInt8(v[start+i])
    return Int64(best_radius)
