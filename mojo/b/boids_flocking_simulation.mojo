from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn trunc_zero(numerator: Int64, denominator: Int64) -> Int64:
    if numerator < 0: return -((-numerator) // denominator)
    return numerator // denominator

fn ceil_sqrt(value: Int64) -> Int64:
    var low: Int64 = 0
    var high: Int64 = 4096
    while low < high:
        let middle = (low + high) // 2
        if middle * middle < value: low = middle + 1
        else: high = middle
    return low

fn cap_vector(x: Int64, y: Int64, limit: Int64) -> InlineArray[Int64, 2]:
    let squared = x * x + y * y
    if squared <= limit * limit: return InlineArray[Int64, 2](x, y)
    if limit == 0: return InlineArray[Int64, 2](0, 0)
    let length = ceil_sqrt(squared)
    return InlineArray[Int64, 2](trunc_zero(x * limit, length), trunc_zero(y * limit, length))

@export("boids_flocking_simulation")
fn boids_flocking_simulation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64 abi("C"):
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 70: return -1
    let count_value = input[0]
    let steps = input[1]
    let radius = input[2]
    let max_speed = input[3]
    let max_acceleration = input[4]
    if count_value < 1 or count_value > 16 or steps < 0 or steps > 16
        or radius < 0 or radius > 128 or max_speed < 1 or max_speed > 32
        or max_acceleration < 0 or max_acceleration > 8
        or length != c_size_t(5 + 4 * count_value): return -1
    let count = Int(count_value)
    var x = InlineArray[Int64, 16](fill=0)
    var y = InlineArray[Int64, 16](fill=0)
    var vx = InlineArray[Int64, 16](fill=0)
    var vy = InlineArray[Int64, 16](fill=0)
    var next_x = InlineArray[Int64, 16](fill=0)
    var next_y = InlineArray[Int64, 16](fill=0)
    var next_vx = InlineArray[Int64, 16](fill=0)
    var next_vy = InlineArray[Int64, 16](fill=0)
    for i in range(count):
        x[i] = input[5 + 4 * i]
        y[i] = input[6 + 4 * i]
        vx[i] = input[7 + 4 * i]
        vy[i] = input[8 + 4 * i]
        if x[i] < -256 or x[i] > 256 or y[i] < -256 or y[i] > 256
            or vx[i] < -32 or vx[i] > 32 or vy[i] < -32 or vy[i] > 32
            or vx[i] * vx[i] + vy[i] * vy[i] > max_speed * max_speed: return -1
    let needed = count * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    let radius_squared = radius * radius
    for _ in range(Int(steps)):
        for i in range(count):
            var separation_x: Int64 = 0
            var separation_y: Int64 = 0
            var velocity_x: Int64 = 0
            var velocity_y: Int64 = 0
            var offset_x: Int64 = 0
            var offset_y: Int64 = 0
            var neighbors: Int64 = 0
            for other in range(count):
                if other == i: continue
                let dx = x[other] - x[i]
                let dy = y[other] - y[i]
                let distance_squared = dx * dx + dy * dy
                if distance_squared > radius_squared: continue
                neighbors += 1
                if distance_squared == 0:
                    if i < other: separation_x -= 256
                    else: separation_x += 256
                else:
                    let length_value = ceil_sqrt(distance_squared)
                    separation_x += trunc_zero(-dx * 256, length_value)
                    separation_y += trunc_zero(-dy * 256, length_value)
                velocity_x += vx[other]
                velocity_y += vy[other]
                offset_x += dx
                offset_y += dy
            var acceleration_x: Int64 = 0
            var acceleration_y: Int64 = 0
            if neighbors > 0:
                let separation = cap_vector(trunc_zero(separation_x, neighbors), trunc_zero(separation_y, neighbors), max_acceleration)
                let alignment = cap_vector(trunc_zero(velocity_x, neighbors) - vx[i], trunc_zero(velocity_y, neighbors) - vy[i], max_acceleration)
                let cohesion = cap_vector(trunc_zero(offset_x, neighbors), trunc_zero(offset_y, neighbors), max_acceleration)
                let requests = InlineArray[InlineArray[Int64, 2], 3](separation, alignment, cohesion)
                var used: Int64 = 0
                for rule in range(3):
                    let remaining = max_acceleration - used
                    if remaining <= 0: break
                    let req_x = requests[rule][0]
                    let req_y = requests[rule][1]
                    let request_length = ceil_sqrt(req_x * req_x + req_y * req_y)
                    if request_length == 0: continue
                    if request_length <= remaining:
                        acceleration_x += req_x
                        acceleration_y += req_y
                        used += request_length
                    else:
                        let trimmed = cap_vector(req_x, req_y, remaining)
                        acceleration_x += trimmed[0]
                        acceleration_y += trimmed[1]
                        break
            let velocity = cap_vector(vx[i] + acceleration_x, vy[i] + acceleration_y, max_speed)
            next_vx[i] = velocity[0]
            next_vy[i] = velocity[1]
            next_x[i] = x[i] + velocity[0]
            next_y[i] = y[i] + velocity[1]
        for i in range(count):
            x[i] = next_x[i]
            y[i] = next_y[i]
            vx[i] = next_vx[i]
            vy[i] = next_vy[i]
    for i in range(count):
        let fields = InlineArray[Int64, 4](x[i], y[i], vx[i], vy[i])
        for field in range(4):
            let bits = bitcast[UInt32](Int32(fields[field]))
            for byte in range(4):
                output[16 * i + 4 * field + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(needed)
