from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PIXELS = 256
comptime NORM_SCALE = 1048576
comptime ANGLE_SCALE = 1000000000
comptime TAN_22_5_Q9 = 414213562

fn clamp_coordinate(coordinate: Int64, side: Int64) -> Int64:
    if coordinate < 0: return 0
    if coordinate >= side: return side - 1
    return coordinate

fn integer_sqrt(value: UInt64) -> UInt64:
    if value < 2: return value
    var low: UInt64 = 1
    var high = value if value < (UInt64(1) << 32) else (UInt64(1) << 32)
    while low <= high:
        let middle = low + (high - low) // 2
        if middle <= value // middle: low = middle + 1
        else: high = middle - 1
    return high

fn gaussian_at(row: Int64, col: Int64) -> Int64:
    let r = row if row >= 0 else -row
    let c = col if col >= 0 else -col
    if r == 0:
        if c == 0: return 85321
        if c == 1: return 66110
        if c == 2: return 30754
        if c == 3: return 8589
        return 1440
    if r == 1:
        if c == 0: return 66110
        if c == 1: return 51225
        if c == 2: return 23829
        if c == 3: return 6655
        return 1116
    if r == 2:
        if c == 0: return 30754
        if c == 1: return 23829
        if c == 2: return 11085
        if c == 3: return 3096
        return 519
    if r == 3:
        if c == 0: return 8589
        if c == 1: return 6655
        if c == 2: return 3096
        if c == 3: return 865
        return 145
    if c == 0: return 1440
    if c == 1: return 1116
    if c == 2: return 519
    if c == 3: return 145
    return 24

fn sobel_x_at(row: Int64, col: Int64) -> Int64:
    if col == 0: return -1 if row != 1 else -2
    if col == 2: return 1 if row != 1 else 2
    return 0

fn sobel_y_at(row: Int64, col: Int64) -> Int64:
    if row == 0: return 2 if col == 1 else 1
    if row == 2: return -2 if col == 1 else -1
    return 0

@export("canny")
fn canny(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257: return -1
    let side = values[0]
    if side < 1 or side > 16: return -1
    let pixels = side * side
    if length != pixels + 1: return -1
    for i in range(pixels):
        if values[i + 1] < 0 or values[i + 1] > 255: return -1
    if capacity < pixels or output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var blurred = InlineArray[Int64, 256](0)
    var gx = InlineArray[Int64, 256](0)
    var gy = InlineArray[Int64, 256](0)
    var nx = InlineArray[Int64, 256](0)
    var ny = InlineArray[Int64, 256](0)
    var magnitude = InlineArray[Int64, 256](0)
    var destination = InlineArray[UInt8, 256](0)
    for row in range(side):
        for col in range(side):
            var total: Int64 = 0
            for ky in range(-4, 5):
                let sr = clamp_coordinate(row + ky, side)
                for kx in range(-4, 5):
                    let sc = clamp_coordinate(col + kx, side)
                    total += gaussian_at(ky, kx) * values[1 + sr * side + sc]
            blurred[row * side + col] = total
    var max_x: Int64 = 0
    var max_y: Int64 = 0
    for row in range(side):
        for col in range(side):
            var total_x: Int64 = 0
            var total_y: Int64 = 0
            for ky in range(3):
                let sr = clamp_coordinate(row + ky - 1, side)
                for kx in range(3):
                    let sc = clamp_coordinate(col + kx - 1, side)
                    let sample = blurred[sr * side + sc]
                    total_x += sample * sobel_x_at(ky, kx)
                    total_y += sample * sobel_y_at(ky, kx)
            if total_x < 0: total_x = -total_x
            if total_y < 0: total_y = -total_y
            let offset = row * side + col
            gx[offset] = total_x
            gy[offset] = total_y
            if total_x > max_x: max_x = total_x
            if total_y > max_y: max_y = total_y
    var max_magnitude: UInt64 = 0
    for i in range(pixels):
        if max_x != 0: nx[i] = gx[i] * 255 * NORM_SCALE // max_x
        if max_y != 0: ny[i] = gy[i] * 255 * NORM_SCALE // max_y
        let ux = UInt64(nx[i])
        let uy = UInt64(ny[i])
        magnitude[i] = Int64(integer_sqrt(ux * ux + uy * uy))
        if UInt64(magnitude[i]) > max_magnitude: max_magnitude = UInt64(magnitude[i])
    if max_magnitude != 0:
        for i in range(pixels): magnitude[i] = magnitude[i] * 255 // Int64(max_magnitude)
    for row in range(1, side - 1):
        for col in range(1, side - 1):
            let offset = row * side + col
            var before: Int64 = 0
            var after: Int64 = 0
            if ny[offset] * ANGLE_SCALE < nx[offset] * TAN_22_5_Q9:
                before = offset - 1
                after = offset + 1
            elif nx[offset] * ANGLE_SCALE <= ny[offset] * TAN_22_5_Q9:
                before = offset - side
                after = offset + side
            else:
                before = offset + side - 1
                after = offset - side + 1
            if magnitude[offset] >= magnitude[before] and magnitude[offset] >= magnitude[after]: destination[offset] = UInt8(magnitude[offset])
    for i in range(pixels):
        if destination[i] >= 30: destination[i] = 255
        elif destination[i] <= 15: destination[i] = 0
        else: destination[i] = 128
    for row in range(1, side - 1):
        for col in range(1, side - 1):
            let offset = row * side + col
            if destination[offset] == 128:
                var connected = False
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        if (dx != 0 or dy != 0) and destination[(row + dy) * side + col + dx] == 255: connected = True
                destination[offset] = 255 if connected else 0
    for i in range(pixels): output[i] = destination[i]
    return pixels
