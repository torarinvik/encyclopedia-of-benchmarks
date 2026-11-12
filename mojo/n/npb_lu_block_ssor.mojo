from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_POINTS = 32
comptime MAX_AXIS = 4
comptime MAX_SWEEPS = 8
comptime MAX_MICRO: Int64 = 1_000_000_000
comptime SCALE = 1_000_000.0

fn _lu_solve5(d: InlineArray[Float64, 25], rhs: InlineArray[Float64, 5],
              inout result: InlineArray[Float64, 5]) -> Bool:
    var a = d
    var b = rhs
    for pivot in range(5):
        let diagonal = a[pivot * 5 + pivot]
        if not (diagonal > 0.0) or not isfinite(diagonal): return False
        for row in range(pivot + 1, 5):
            let factor = a[row * 5 + pivot] / diagonal
            for column in range(pivot + 1, 5):
                a[row * 5 + column] -= factor * a[pivot * 5 + column]
            b[row] -= factor * b[pivot]
    for back in range(5):
        let row = 4 - back
        var tail: Float64 = 0.0
        for column in range(row + 1, 5):
            tail += a[row * 5 + column] * result[column]
        result[row] = (b[row] - tail) / a[row * 5 + row]
    return True

fn _lu_apply(nx: Int, ny: Int, nz: Int, d: InlineArray[Float64, 25],
             c: InlineArray[Float64, 3], x: InlineArray[Float64, 160],
             inout out: InlineArray[Float64, 160]):
    let points = nx * ny * nz
    let nxy = nx * ny
    for point in range(points):
        let ix = point % nx
        let iy = (point // nx) % ny
        let iz = point // nxy
        for row in range(5):
            var total: Float64 = 0.0
            for column in range(5): total += d[row * 5 + column] * x[point * 5 + column]
            if ix > 0: total += c[0] * x[(point - 1) * 5 + row]
            if ix + 1 < nx: total += c[0] * x[(point + 1) * 5 + row]
            if iy > 0: total += c[1] * x[(point - nx) * 5 + row]
            if iy + 1 < ny: total += c[1] * x[(point + nx) * 5 + row]
            if iz > 0: total += c[2] * x[(point - nxy) * 5 + row]
            if iz + 1 < nz: total += c[2] * x[(point + nxy) * 5 + row]
            out[point * 5 + row] = total

fn _lu_valid(v: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Bool:
    if length < 42 or length > 352: return False
    if v[0] < 1 or v[0] > Int64(MAX_AXIS) or v[1] < 1 or v[1] > Int64(MAX_AXIS) or
        v[2] < 1 or v[2] > Int64(MAX_AXIS) or v[3] < 1 or v[3] > Int64(MAX_SWEEPS):
        return False
    let nx = Int(v[0]); let ny = Int(v[1]); let nz = Int(v[2])
    let points = nx * ny * nz
    if points > MAX_POINTS or length != 32 + 10 * points: return False
    for index in range(4, length):
        if v[index] < -MAX_MICRO or v[index] > MAX_MICRO: return False
    for row in range(5):
        let diagonal = v[4 + row * 5 + row]
        var off_sum: Int64 = 0
        for column in range(5):
            let entry = v[4 + row * 5 + column]
            if entry != v[4 + column * 5 + row]: return False
            if row != column:
                off_sum += if entry < 0 then -entry else entry
        if nx > 1: off_sum += 2 * (if v[29] < 0 then -v[29] else v[29])
        if ny > 1: off_sum += 2 * (if v[30] < 0 then -v[30] else v[30])
        if nz > 1: off_sum += 2 * (if v[31] < 0 then -v[31] else v[31])
        if diagonal <= 0 or diagonal <= off_sum: return False
    return True

@export("npb_lu_block_ssor")
fn npb_lu_block_ssor(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or not _lu_valid(values, Int(length)):
        return -1
    let nx = Int(values[0]); let ny = Int(values[1]); let nz = Int(values[2])
    let sweeps = Int(values[3]); let points = nx * ny * nz; let count = 5 * points
    let output_bytes = 8 * (sweeps + count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var d = InlineArray[Float64, 25]()
    var c = InlineArray[Float64, 3]()
    var x = InlineArray[Float64, 160]()
    var rhs = InlineArray[Float64, 160]()
    var applied = InlineArray[Float64, 160]()
    var residual = InlineArray[Float64, 160]()
    var forward = InlineArray[Float64, 160]()
    var correction = InlineArray[Float64, 160]()
    for index in range(25): d[index] = Float64(values[4 + index]) / SCALE
    for axis in range(3): c[axis] = Float64(values[29 + axis]) / SCALE
    for index in range(count):
        rhs[index] = Float64(values[32 + index]) / SCALE
        x[index] = Float64(values[32 + count + index]) / SCALE
    let nxy = nx * ny
    for sweep in range(sweeps):
        _lu_apply(nx, ny, nz, d, c, x, applied)
        for index in range(count): residual[index] = rhs[index] - applied[index]
        for point in range(points):
            let ix = point % nx; let iy = (point // nx) % ny; let iz = point // nxy
            var local = InlineArray[Float64, 5]()
            var solved = InlineArray[Float64, 5]()
            for row in range(5): local[row] = residual[point * 5 + row]
            if ix > 0:
                for row in range(5): local[row] -= c[0] * forward[(point - 1) * 5 + row]
            if iy > 0:
                for row in range(5): local[row] -= c[1] * forward[(point - nx) * 5 + row]
            if iz > 0:
                for row in range(5): local[row] -= c[2] * forward[(point - nxy) * 5 + row]
            if not _lu_solve5(d, local, solved): return -1
            for row in range(5): forward[point * 5 + row] = solved[row]
        for back in range(points):
            let point = points - 1 - back
            let ix = point % nx; let iy = (point // nx) % ny; let iz = point // nxy
            var local = InlineArray[Float64, 5]()
            var solved = InlineArray[Float64, 5]()
            for row in range(5):
                for column in range(5): local[row] += d[row * 5 + column] * forward[point * 5 + column]
            if ix + 1 < nx:
                for row in range(5): local[row] -= c[0] * correction[(point + 1) * 5 + row]
            if iy + 1 < ny:
                for row in range(5): local[row] -= c[1] * correction[(point + nx) * 5 + row]
            if iz + 1 < nz:
                for row in range(5): local[row] -= c[2] * correction[(point + nxy) * 5 + row]
            if not _lu_solve5(d, local, solved): return -1
            for row in range(5): correction[point * 5 + row] = solved[row]
        for index in range(count): x[index] += correction[index]
        _lu_apply(nx, ny, nz, d, c, x, applied)
        var norm2: Float64 = 0.0
        for index in range(count):
            let difference = rhs[index] - applied[index]
            norm2 += difference * difference
        let norm = sqrt(norm2)
        if not isfinite(norm): return -1
        let bits = bitcast[UInt64](norm)
        for byte in range(8): output[sweep * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    for index in range(count):
        let bits = bitcast[UInt64](x[index])
        for byte in range(8): output[(sweeps + index) * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(output_bytes)
