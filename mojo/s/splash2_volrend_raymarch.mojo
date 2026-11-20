from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_SIDE = 8
comptime MAX_RAYS = 16
comptime MAX_SAMPLES = 32
comptime MAX_VOXELS = MAX_SIDE * MAX_SIDE * MAX_SIDE
comptime MAX_PARSEABLE = 3 + 2 * MAX_VOXELS + 6 * MAX_RAYS + 1
comptime MAX_MASKS = 4 * MAX_VOXELS
comptime Q8: Int64 = 256
comptime Q16: Int64 = 65536
comptime WEIGHT_DEN: Int64 = 16777216
comptime ALPHA_DEN: Int64 = 255 * WEIGHT_DEN
comptime COLOR_DEN: Int64 = 255 * 255 * WEIGHT_DEN

fn vrm_voxel_index(side: Int, x: Int, y: Int, z: Int) -> Int:
    return (z * side + y) * side + x

fn vrm_mask_index(level: Int, x: Int, y: Int, z: Int) -> Int:
    return ((level * 8 + z) * 8 + y) * 8 + x

fn vrm_round_half_up(numerator: Int64, denominator: Int64) -> Int64:
    return (numerator + denominator / 2) / denominator

fn vrm_byte(q16: Int64) -> UInt8:
    return UInt8((q16 * 255 + Q16 / 2) / Q16)

@export("splash2_volrend_raymarch")
fn splash2_volrend_raymarch(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_PARSEABLE):
        return -1
    let side_raw = input[0]
    let ray_raw = input[1]
    let sample_raw = input[2]
    if (side_raw != 2 and side_raw != 4 and side_raw != 8) or ray_raw < 1 or ray_raw > MAX_RAYS or sample_raw < 1 or sample_raw > MAX_SAMPLES:
        return -1
    let side = Int(side_raw)
    let ray_count = Int(ray_raw)
    let sample_count = Int(sample_raw)
    let voxel_count = side * side * side
    let ray_start = 3 + 2 * voxel_count
    if length != c_size_t(ray_start + 6 * ray_count):
        return -1

    var alpha = InlineArray[UInt8, MAX_VOXELS](fill=0)
    var gray = InlineArray[UInt8, MAX_VOXELS](fill=0)
    var rays = InlineArray[Int32, MAX_RAYS * 6](fill=0)
    for voxel in range(voxel_count):
        let a = input[3 + 2 * voxel]
        let g = input[4 + 2 * voxel]
        if a < 0 or a > 255 or g < 0 or g > 255:
            return -1
        alpha[voxel] = UInt8(a)
        gray[voxel] = UInt8(g)

    let coordinate_max = Int64(side - 1) * Q8
    for ray in range(ray_count):
        let at = ray_start + 6 * ray
        for axis in range(3):
            let origin = input[at + axis]
            let delta = input[at + axis + 3]
            if origin < 0 or origin > coordinate_max or delta < -coordinate_max or delta > coordinate_max:
                return -1
            rays[6 * ray + axis] = Int32(origin)
            rays[6 * ray + axis + 3] = Int32(delta)
        if sample_count > 1 and rays[6 * ray + 3] == 0 and rays[6 * ray + 4] == 0 and rays[6 * ray + 5] == 0:
            return -1
        for sample in range(sample_count):
            for axis in range(3):
                let q = Int64(rays[6 * ray + axis]) + Int64(sample) * Int64(rays[6 * ray + axis + 3])
                if q < 0 or q > coordinate_max:
                    return -1

    let output_bytes = 5 * ray_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]():
        return -2
    if capacity < c_size_t(output_bytes):
        return -3

    var support = InlineArray[UInt8, MAX_MASKS](fill=0)
    for z in range(side):
        for y in range(side):
            for x in range(side):
                var occupied: UInt8 = 0
                for dz in range(2):
                    for dy in range(2):
                        for dx in range(2):
                            let nx = min(x + dx, side - 1)
                            let ny = min(y + dy, side - 1)
                            let nz = min(z + dz, side - 1)
                            if alpha[vrm_voxel_index(side, nx, ny, nz)] != 0:
                                occupied = 1
                support[vrm_mask_index(0, x, y, z)] = occupied

    var levels = 0
    var dimension = side
    while dimension > 1:
        dimension = dimension / 2
        levels += 1
    for level in range(1, levels + 1):
        let dim = side >> level
        for z in range(dim):
            for y in range(dim):
                for x in range(dim):
                    var occupied: UInt8 = 0
                    for dz in range(2):
                        for dy in range(2):
                            for dx in range(2):
                                if support[vrm_mask_index(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)] != 0:
                                    occupied = 1
                    support[vrm_mask_index(level, x, y, z)] = occupied

    for ray in range(ray_count):
        var accumulated_alpha: Int64 = 0
        var accumulated_gray: Int64 = 0
        var used = 0
        for sample in range(sample_count):
            used = sample + 1
            let xq = Int64(rays[6 * ray]) + Int64(sample) * Int64(rays[6 * ray + 3])
            let yq = Int64(rays[6 * ray + 1]) + Int64(sample) * Int64(rays[6 * ray + 4])
            let zq = Int64(rays[6 * ray + 2]) + Int64(sample) * Int64(rays[6 * ray + 5])
            let cx = Int(xq / Q8)
            let cy = Int(yq / Q8)
            let cz = Int(zq / Q8)
            var supported = True
            for level in range(levels, -1, -1):
                if support[vrm_mask_index(level, cx >> level, cy >> level, cz >> level)] == 0:
                    supported = False
                    break
            if supported:
                let low_x = cx
                let low_y = cy
                let low_z = cz
                let fx = Int(xq % Q8)
                let fy = Int(yq % Q8)
                let fz = Int(zq % Q8)
                let high_x = min(low_x + 1, side - 1)
                let high_y = min(low_y + 1, side - 1)
                let high_z = min(low_z + 1, side - 1)
                var opacity_sum: Int64 = 0
                var premul_sum: Int64 = 0
                for dz in range(2):
                    let iz = low_z if dz == 0 else high_z
                    let wz = Int64(256 - fz) if dz == 0 else Int64(fz)
                    for dy in range(2):
                        let iy = low_y if dy == 0 else high_y
                        let wy = Int64(256 - fy) if dy == 0 else Int64(fy)
                        for dx in range(2):
                            let ix = low_x if dx == 0 else high_x
                            let wx = Int64(256 - fx) if dx == 0 else Int64(fx)
                            let at = vrm_voxel_index(side, ix, iy, iz)
                            let weight = wx * wy * wz
                            opacity_sum += Int64(alpha[at]) * weight
                            premul_sum += Int64(alpha[at]) * Int64(gray[at]) * weight
                let sample_alpha = vrm_round_half_up(opacity_sum * Q16, ALPHA_DEN)
                let sample_gray = vrm_round_half_up(premul_sum * Q16, COLOR_DEN)
                let remaining = Q16 - accumulated_alpha
                accumulated_alpha = min(Q16, accumulated_alpha + vrm_round_half_up(remaining * sample_alpha, Q16))
                accumulated_gray = min(Q16, accumulated_gray + vrm_round_half_up(remaining * sample_gray, Q16))
                if accumulated_alpha == Q16:
                    break

        let at = 5 * ray
        let value = vrm_byte(accumulated_gray)
        output[at] = value
        output[at + 1] = value
        output[at + 2] = value
        output[at + 3] = vrm_byte(accumulated_alpha)
        output[at + 4] = UInt8(used)
    return Int64(output_bytes)
