# Independent bounded Welzl profile; see the package MIT LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import floor, isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ball_contains(s: InlineArray[Float64, 4], points: InlineArray[Float64, 24], id: Int) -> Bool:
    if s[3] < 0.0: return False
    var distance: Float64 = 0.0
    for axis in range(3):
        let d = points[3 * id + axis] - s[axis]
        distance += d * d
    let radius = s[3] + 1.0e-10
    return distance <= radius * radius

fn ball_through(points: InlineArray[Float64, 24], support: InlineArray[Int, 4], count: Int) -> InlineArray[Float64, 4]:
    var result = InlineArray[Float64, 4](0.0, 0.0, 0.0, -1.0)
    if count == 0: return result
    let first = support[0]
    if count == 1:
        for axis in range(3): result[axis] = points[first * 3 + axis]
        result[3] = 0.0
        return result
    # The center offset lies in the span of the support differences. Solve
    # their Gram system; singular supports are handled by smaller subsets.
    let dimension = count - 1
    var vectors = InlineArray[Float64, 9](fill=0.0)
    var matrix = InlineArray[Float64, 12](fill=0.0)
    for row in range(dimension):
        for axis in range(3): vectors[3 * row + axis] = points[3 * support[row + 1] + axis] - points[3 * first + axis]
    for row in range(dimension):
        for col in range(dimension):
            var product: Float64 = 0.0
            for axis in range(3): product += vectors[3 * row + axis] * vectors[3 * col + axis]
            matrix[4 * row + col] = product
        matrix[4 * row + dimension] = matrix[4 * row + row] / 2.0
    for col in range(dimension):
        var pivot = col
        for row in range(col + 1, dimension):
            if abs(matrix[4 * row + col]) > abs(matrix[4 * pivot + col]): pivot = row
        if abs(matrix[4 * pivot + col]) < 1.0e-24: return result
        if pivot != col:
            for j in range(col, dimension + 1):
                let temporary = matrix[4 * col + j]
                matrix[4 * col + j] = matrix[4 * pivot + j]
                matrix[4 * pivot + j] = temporary
        let scale = matrix[4 * col + col]
        for j in range(col, dimension + 1): matrix[4 * col + j] /= scale
        for row in range(dimension):
            if row == col: continue
            let factor = matrix[4 * row + col]
            for j in range(col, dimension + 1): matrix[4 * row + j] -= factor * matrix[4 * col + j]
    var radius2: Float64 = 0.0
    for axis in range(3):
        var offset: Float64 = 0.0
        for row in range(dimension): offset += matrix[4 * row + dimension] * vectors[3 * row + axis]
        result[axis] = points[3 * first + axis] + offset
        radius2 += offset * offset
    result[3] = sqrt(radius2)
    return result

fn ball_fit(points: InlineArray[Float64, 24], boundary: InlineArray[Int, 4], count: Int) -> InlineArray[Float64, 4]:
    var best = InlineArray[Float64, 4](0.0, 0.0, 0.0, -1.0)
    for mask in range(1, 1 << count):
        var subset = InlineArray[Int, 4](fill=0)
        var used = 0
        for i in range(count):
            if (mask & (1 << i)) != 0:
                subset[used] = boundary[i]
                used += 1
        let candidate = ball_through(points, subset, used)
        if candidate[3] < 0.0: continue
        var covers = True
        for i in range(count):
            if not ball_contains(candidate, points, boundary[i]): covers = False
        if covers and (best[3] < 0.0 or candidate[3] < best[3] - 1.0e-12): best = candidate
    return best

fn ball_welzl(points: InlineArray[Float64, 24], n: Int, inout boundary: InlineArray[Int, 4], count: Int) -> InlineArray[Float64, 4]:
    if n == 0 or count == 4: return ball_fit(points, boundary, count)
    let candidate = ball_welzl(points, n - 1, boundary, count)
    if ball_contains(candidate, points, n - 1): return candidate
    boundary[count] = n - 1
    return ball_welzl(points, n - 1, boundary, count + 1)

@export("smallest_enclosing_ball_3d")
fn smallest_enclosing_ball_3d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 4 or length > 25: return -1
    let raw = input[0]
    if not isfinite(raw) or raw < 1.0 or raw > 8.0 or floor(raw) != raw: return -1
    let n = Int(raw)
    if Int(length) != 1 + 3 * n: return -1
    var points = InlineArray[Float64, 24](fill=0.0)
    for i in range(3 * n):
        let value = input[1 + i]
        if not isfinite(value) or value < -10.0 or value > 10.0: return -1
        points[i] = value
    for i in range(1, n):
        let px = points[3 * i]
        let py = points[3 * i + 1]
        let pz = points[3 * i + 2]
        var j = i
        while j > 0 and (points[3 * (j - 1)] > px or
                (points[3 * (j - 1)] == px and (points[3 * (j - 1) + 1] > py or
                 (points[3 * (j - 1) + 1] == py and points[3 * (j - 1) + 2] > pz)))):
            for axis in range(3): points[3 * j + axis] = points[3 * (j - 1) + axis]
            j -= 1
        points[3 * j] = px
        points[3 * j + 1] = py
        points[3 * j + 2] = pz
    var boundary = InlineArray[Int, 4](fill=0)
    let sphere = ball_welzl(points, n, boundary, 0)
    if sphere[3] < 0.0 or not isfinite(sphere[3]): return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 4: return -2
    for i in range(4): output[i] = sphere[i]
    return 4
