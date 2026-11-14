from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn udg_count(mask: Int) -> Int:
    var remaining = mask
    var count = 0
    while remaining != 0:
        count += remaining & 1
        remaining >>= 1
    return count

fn udg_left(mask: Int) -> Int:
    let half = udg_count(mask) // 2
    var result = 0
    var seen = 0
    for i in range(8):
        if (mask & (1 << i)) != 0:
            if seen < half: result |= 1 << i
            seen += 1
    return result

fn udg_cross(n: Int, factor: Int64, distance: InlineArray[Int64, 64], a: Int, b: Int,
             inout pairs: InlineArray[Int64, 56], inout count: Int):
    var diameter_a: Int64 = 0
    var diameter_b: Int64 = 0
    var nearest: Int64 = 1000
    for i in range(n):
        for j in range(n):
            let d = distance[8 * i + j]
            if (a & (1 << i)) != 0 and (a & (1 << j)) != 0: diameter_a = max(diameter_a, d)
            if (b & (1 << i)) != 0 and (b & (1 << j)) != 0: diameter_b = max(diameter_b, d)
            if (a & (1 << i)) != 0 and (b & (1 << j)) != 0: nearest = min(nearest, d)
    if nearest >= factor * max(diameter_a, diameter_b):
        pairs[2 * count] = Int64(a)
        pairs[2 * count + 1] = Int64(b)
        count += 1
    elif udg_count(a) >= udg_count(b) and udg_count(a) > 1:
        let left = udg_left(a)
        udg_cross(n, factor, distance, left, b, pairs, count)
        udg_cross(n, factor, distance, a ^ left, b, pairs, count)
    else:
        let left = udg_left(b)
        udg_cross(n, factor, distance, a, left, pairs, count)
        udg_cross(n, factor, distance, a, b ^ left, pairs, count)

fn udg_visit(n: Int, factor: Int64, distance: InlineArray[Int64, 64], mask: Int,
             inout pairs: InlineArray[Int64, 56], inout count: Int):
    if udg_count(mask) < 2: return
    let left = udg_left(mask)
    let right = mask ^ left
    udg_visit(n, factor, distance, left, pairs, count)
    udg_visit(n, factor, distance, right, pairs, count)
    udg_cross(n, factor, distance, left, right, pairs, count)

@export("unit_disk_graph_wspd")
fn unit_disk_graph_wspd(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 18: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8: return -1
    let n = Int(input[0])
    if Int(length) != 2 + 2 * n: return -1
    for i in range(n):
        let x = input[2 + 2 * i]
        let y = input[3 + 2 * i]
        if x < -8 or x > 8 or y < -8 or y > 8: return -1
        for j in range(i):
            if x == input[2 + 2 * j] and y == input[3 + 2 * j]: return -1
    var distance = InlineArray[Int64, 64](fill=1000)
    for i in range(n):
        distance[8 * i + i] = 0
        for j in range(i + 1, n):
            let dx = input[2 + 2 * i] - input[2 + 2 * j]
            let dy = input[3 + 2 * i] - input[3 + 2 * j]
            if dx * dx + dy * dy <= 1:
                distance[8 * i + j] = 1
                distance[8 * j + i] = 1
    for k in range(n):
        for i in range(n):
            for j in range(n):
                distance[8 * i + j] = min(distance[8 * i + j], distance[8 * i + k] + distance[8 * k + j])
    for i in range(n):
        for j in range(n):
            if distance[8 * i + j] >= 1000: return -1
    var pairs = InlineArray[Int64, 56](fill=0)
    var count = 0
    udg_visit(n, input[1], distance, (1 << n) - 1, pairs, count)
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(1 + 2 * count):
        var value = Int64(count)
        if word > 0: value = pairs[word - 1]
        var bits = UInt64(value)
        for b in range(8):
            output[8 * word + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
