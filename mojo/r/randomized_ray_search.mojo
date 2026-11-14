from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ray_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("randomized_ray_search")
fn randomized_ray_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 11: return -1
    let rays_value = input[0]
    let growth = input[1]
    let initial = input[2]
    if rays_value < 2 or rays_value > 5 or growth < 2 or growth > 4 or initial < 1000 or initial >= growth * 1000 or length != c_size_t(rays_value + 5): return -1
    let rays = Int(rays_value)
    var order = InlineArray[Int64, 5](fill=0)
    var seen = InlineArray[Bool, 5](fill=False)
    for i in range(rays):
        let ray = input[3 + i]
        if ray < 0 or ray >= rays_value: return -1
        if seen[Int(ray)]: return -1
        seen[Int(ray)] = True
        order[i] = ray
    let target = input[3 + rays]
    let target_distance = input[4 + rays]
    if target < 0 or target >= rays_value or target_distance < 1 or target_distance > 1000000000: return -1
    var distance = initial
    var total: Int64 = 0
    var attempts: Int64 = 0
    var found = False
    for round in range(32):
        attempts += 1
        if order[round % rays] == target and target_distance <= distance:
            total += target_distance
            found = True
            break
        total += 2 * distance
        distance *= growth
    if not found: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    ray_store(output, 0, attempts)
    ray_store(output, 1, total)
    return 16
