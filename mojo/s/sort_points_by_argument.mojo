from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 64
const INPUT_MAX = 129

fn point_less(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Bool:
    var ah = 2
    var bh = 2
    if ay < 0: ah = 0
    elif ay == 0 and ax >= 0: ah = 1
    if by < 0: bh = 0
    elif by == 0 and bx >= 0: bh = 1
    if ah != bh: return ah < bh
    let determinant = ax * by - ay * bx
    if determinant != 0: return determinant > 0
    let ar = ax * ax + ay * ay
    let br = bx * bx + by * by
    if ar != br: return ar < br
    if ax != bx: return ax < bx
    return ay < by

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("sort_points_by_argument")
fn sort_points_by_argument(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > INPUT_MAX: return -1
    let nr = input[0]
    if nr < 1 or nr > MAX_N or length != c_size_t(1 + 2 * nr): return -1
    let n = Int(nr)
    var xs = InlineArray[Int64, MAX_N]()
    var ys = InlineArray[Int64, MAX_N]()
    for i in range(n):
        let x = input[1 + 2 * i]
        let y = input[2 + 2 * i]
        if x < -1000000000 or x > 1000000000 or y < -1000000000 or y > 1000000000: return -1
        xs[i] = x
        ys[i] = y
    let required = 16 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for i in range(1, n):
        let item_x = xs[i]
        let item_y = ys[i]
        var j = i
        while j > 0 and point_less(item_x, item_y, xs[j - 1], ys[j - 1]):
            xs[j] = xs[j - 1]
            ys[j] = ys[j - 1]
            j -= 1
        xs[j] = item_x
        ys[j] = item_y
    for i in range(n):
        store_le(output, 16 * i, xs[i])
        store_le(output, 16 * i + 8, ys[i])
    return Int64(required)
