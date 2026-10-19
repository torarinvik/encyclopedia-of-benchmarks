from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("affine_image_rotation")
fn affine_image_rotation(input: UnsafePointer[Int32, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int32, ImmutAnyOrigin]() or length < 2 or length > 79:
        return -1
    let rows = input[0]
    let cols = input[1]
    if rows < 1 or rows > 8 or cols < 1 or cols > 8:
        return -1
    let cells = Int(rows * cols)
    if length != c_size_t(14 + cells):
        return -1
    var pixels = List[UInt8](length=cells, fill=0)
    for i in range(cells):
        let v = input[2 + i]
        if v < 0 or v > 255:
            return -1
        pixels[i] = UInt8(v)
    let p = 2 + cells
    var sx = List[Int64](length=3, fill=0)
    var sy = List[Int64](length=3, fill=0)
    var dx = List[Int64](length=3, fill=0)
    var dy = List[Int64](length=3, fill=0)
    for i in range(3):
        sx[i] = Int64(input[p + 2 * i])
        sy[i] = Int64(input[p + 2 * i + 1])
        dx[i] = Int64(input[p + 6 + 2 * i])
        dy[i] = Int64(input[p + 7 + 2 * i])
        if sx[i] < -16 or sx[i] > 16 or sy[i] < -16 or sy[i] > 16 or dx[i] < -16 or dx[i] > 16 or dy[i] < -16 or dy[i] > 16:
            return -1
    let determinant = sx[0] * (sy[1] - sy[2]) + sx[1] * (sy[2] - sy[0]) + sx[2] * (sy[0] - sy[1])
    if determinant == 0:
        return -1
    var coeff_a = List[Int64](length=2, fill=0)
    var coeff_b = List[Int64](length=2, fill=0)
    var trans = List[Int64](length=2, fill=0)
    for axis in range(2):
        var t0 = dx[0]
        var t1 = dx[1]
        var t2 = dx[2]
        if axis == 1:
            t0 = dy[0]
            t1 = dy[1]
            t2 = dy[2]
        let an = t0 * (sy[1] - sy[2]) + t1 * (sy[2] - sy[0]) + t2 * (sy[0] - sy[1])
        let bn = sx[0] * (t1 - t2) + sx[1] * (t2 - t0) + sx[2] * (t0 - t1)
        let tn = sx[0] * (sy[1] * t2 - sy[2] * t1) + sx[1] * (sy[2] * t0 - sy[0] * t2) + sx[2] * (sy[0] * t1 - sy[1] * t0)
        if an % determinant != 0 or bn % determinant != 0 or tn % determinant != 0:
            return -1
        coeff_a[axis] = an / determinant
        coeff_b[axis] = bn / determinant
        trans[axis] = tn / determinant
    let a = coeff_a[0]
    let b = coeff_b[0]
    let tx = trans[0]
    let c = coeff_a[1]
    let d = coeff_b[1]
    let ty = trans[1]
    if a < -2 or a > 2 or b < -2 or b > 2 or c < -2 or c > 2 or d < -2 or d > 2 or tx < -16 or tx > 16 or ty < -16 or ty > 16:
        return -1
    let det = a * d - b * c
    if det != -1 and det != 1:
        return -1
    for i in range(3):
        if dx[i] != a * sx[i] + b * sy[i] + tx or dy[i] != c * sx[i] + d * sy[i] + ty:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(cells):
        return -2
    var written = 0
    for oy in range(Int(cols)):
        for ox in range(Int(rows)):
            let x = Int64(ox) - tx
            let y = Int64(oy) - ty
            let source_col = (d * x - b * y) / det
            let source_row = (-c * x + a * y) / det
            if source_col >= 0 and source_col < Int64(cols) and source_row >= 0 and source_row < Int64(rows):
                output[written] = pixels[Int(source_row * Int64(cols) + source_col)]
            else:
                output[written] = 0
            written += 1
    return Int64(cells)
