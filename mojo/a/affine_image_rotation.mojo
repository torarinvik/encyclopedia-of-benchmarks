from std.ffi import c_size_t
from std.memory import Pointer, stack_allocation

@export("affine_image_rotation")
def affine_image_rotation(input_address: UInt64, length: c_size_t,
                         output_address: UInt64, capacity: c_size_t) abi("C") -> Int64:
    if input_address == 0 or length < 2 or length > 79:
        return -1
    var input = Pointer[Int32, UntrackedOrigin[mut=False]](unsafe_from_address=Int(input_address))
    var rows = input[unsafe_offset=0]
    var cols = input[unsafe_offset=1]
    if rows < 1 or rows > 8 or cols < 1 or cols > 8:
        return -1
    var cells = Int(rows * cols)
    if length != c_size_t(14 + cells):
        return -1
    var pixels = stack_allocation[64, UInt8]()
    for i in range(cells):
        var v = input[unsafe_offset=2 + i]
        if v < 0 or v > 255:
            return -1
        pixels[unsafe_offset=i] = UInt8(v)
    var p = 2 + cells
    var sx = stack_allocation[3, Int64]()
    var sy = stack_allocation[3, Int64]()
    var dx = stack_allocation[3, Int64]()
    var dy = stack_allocation[3, Int64]()
    for i in range(3):
        sx[unsafe_offset=i] = Int64(input[unsafe_offset=p + 2 * i])
        sy[unsafe_offset=i] = Int64(input[unsafe_offset=p + 2 * i + 1])
        dx[unsafe_offset=i] = Int64(input[unsafe_offset=p + 6 + 2 * i])
        dy[unsafe_offset=i] = Int64(input[unsafe_offset=p + 7 + 2 * i])
        if sx[unsafe_offset=i] < -16 or sx[unsafe_offset=i] > 16 or sy[unsafe_offset=i] < -16 or sy[unsafe_offset=i] > 16 or dx[unsafe_offset=i] < -16 or dx[unsafe_offset=i] > 16 or dy[unsafe_offset=i] < -16 or dy[unsafe_offset=i] > 16:
            return -1
    var determinant = sx[unsafe_offset=0] * (sy[unsafe_offset=1] - sy[unsafe_offset=2]) + sx[unsafe_offset=1] * (sy[unsafe_offset=2] - sy[unsafe_offset=0]) + sx[unsafe_offset=2] * (sy[unsafe_offset=0] - sy[unsafe_offset=1])
    if determinant == 0:
        return -1
    var coeff_a = stack_allocation[2, Int64]()
    var coeff_b = stack_allocation[2, Int64]()
    var trans = stack_allocation[2, Int64]()
    for axis in range(2):
        var t0 = dx[unsafe_offset=0]
        var t1 = dx[unsafe_offset=1]
        var t2 = dx[unsafe_offset=2]
        if axis == 1:
            t0 = dy[unsafe_offset=0]
            t1 = dy[unsafe_offset=1]
            t2 = dy[unsafe_offset=2]
        var an = t0 * (sy[unsafe_offset=1] - sy[unsafe_offset=2]) + t1 * (sy[unsafe_offset=2] - sy[unsafe_offset=0]) + t2 * (sy[unsafe_offset=0] - sy[unsafe_offset=1])
        var bn = sx[unsafe_offset=0] * (t1 - t2) + sx[unsafe_offset=1] * (t2 - t0) + sx[unsafe_offset=2] * (t0 - t1)
        var tn = sx[unsafe_offset=0] * (sy[unsafe_offset=1] * t2 - sy[unsafe_offset=2] * t1) + sx[unsafe_offset=1] * (sy[unsafe_offset=2] * t0 - sy[unsafe_offset=0] * t2) + sx[unsafe_offset=2] * (sy[unsafe_offset=0] * t1 - sy[unsafe_offset=1] * t0)
        if an % determinant != 0 or bn % determinant != 0 or tn % determinant != 0:
            return -1
        coeff_a[unsafe_offset=axis] = an / determinant
        coeff_b[unsafe_offset=axis] = bn / determinant
        trans[unsafe_offset=axis] = tn / determinant
    var a = coeff_a[unsafe_offset=0]
    var b = coeff_b[unsafe_offset=0]
    var tx = trans[unsafe_offset=0]
    var c = coeff_a[unsafe_offset=1]
    var d = coeff_b[unsafe_offset=1]
    var ty = trans[unsafe_offset=1]
    if a < -2 or a > 2 or b < -2 or b > 2 or c < -2 or c > 2 or d < -2 or d > 2 or tx < -16 or tx > 16 or ty < -16 or ty > 16:
        return -1
    var det = a * d - b * c
    if det != -1 and det != 1:
        return -1
    for i in range(3):
        if dx[unsafe_offset=i] != a * sx[unsafe_offset=i] + b * sy[unsafe_offset=i] + tx or dy[unsafe_offset=i] != c * sx[unsafe_offset=i] + d * sy[unsafe_offset=i] + ty:
            return -1
    if output_address == 0 or capacity < c_size_t(cells):
        return -2
    var output = Pointer[UInt8, UntrackedOrigin[mut=True]](unsafe_from_address=Int(output_address))
    var written = 0
    for oy in range(Int(cols)):
        for ox in range(Int(rows)):
            var x = Int64(ox) - tx
            var y = Int64(oy) - ty
            var source_col = (d * x - b * y) / det
            var source_row = (-c * x + a * y) / det
            if source_col >= 0 and source_col < Int64(cols) and source_row >= 0 and source_row < Int64(rows):
                output[unsafe_offset=written] = pixels[unsafe_offset=Int(source_row * Int64(cols) + source_col)]
            else:
                output[unsafe_offset=written] = 0
            written += 1
    return Int64(cells)
