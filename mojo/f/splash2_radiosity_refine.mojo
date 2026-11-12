from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_DEPTH = 5

fn splash2_radiosity_factor(tx: Float64, ty: Float64, source_area: Float64,
                            sx: Float64, sy: Float64, gap: Float64) -> Float64:
    let distance_squared = (sx - tx) * (sx - tx) + (sy - ty) * (sy - ty) + gap * gap
    return source_area * gap * gap / (distance_squared * distance_squared)

fn splash2_radiosity_visit(tx: Float64, ty: Float64, target_side: Float64,
                           sx: Float64, sy: Float64, source_side: Float64,
                           gap: Float64, bound: Float64, allowed_depth: Int,
                           depth: Int, weight: Float64, inout transfer: Float64,
                           inout leaves: Int, inout deepest: Int):
    let coarse = splash2_radiosity_factor(tx, ty, source_side * source_side, sx, sy, gap)
    let split_source = source_side >= target_side
    let parent_side = source_side if split_source else target_side
    let child_side = parent_side * 0.5
    let offset = parent_side * 0.25
    var fine = 0.0
    for quadrant in range(4):
        let dx = offset if (quadrant & 1) != 0 else -offset
        let dy = offset if (quadrant & 2) != 0 else -offset
        if split_source:
            fine += splash2_radiosity_factor(tx, ty, child_side * child_side,
                                               sx + dx, sy + dy, gap)
        else:
            fine += 0.25 * splash2_radiosity_factor(tx + dx, ty + dy,
                source_side * source_side, sx, sy, gap)
    var error = fine - coarse
    if error < 0.0:
        error = -error
    if depth >= allowed_depth or error <= bound:
        transfer += weight * coarse
        leaves += 1
        if depth > deepest:
            deepest = depth
        return
    for quadrant in range(4):
        let dx = offset if (quadrant & 1) != 0 else -offset
        let dy = offset if (quadrant & 2) != 0 else -offset
        if split_source:
            splash2_radiosity_visit(tx, ty, target_side, sx + dx, sy + dy,
                child_side, gap, bound, allowed_depth, depth + 1, weight,
                transfer, leaves, deepest)
        else:
            splash2_radiosity_visit(tx + dx, ty + dy, child_side, sx, sy,
                source_side, gap, bound, allowed_depth, depth + 1, weight * 0.25,
                transfer, leaves, deepest)

@export("splash2_radiosity_refine")
fn splash2_radiosity_refine(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length != 11:
        return -1
    for index in range(11):
        if input[index] != input[index]:
            return -1
    let tx = input[0]
    let ty = input[1]
    let target_side = input[2]
    let sx = input[3]
    let sy = input[4]
    let source_side = input[5]
    let gap = input[6]
    let brightness = input[7]
    let reflectance = input[8]
    let bound = input[9]
    let depth_value = input[10]
    if tx < -8 or tx > 8 or ty < -8 or ty > 8 or sx < -8 or sx > 8 or sy < -8 or sy > 8:
        return -1
    if (target_side != 1 and target_side != 2 and target_side != 4) or (source_side != 1 and source_side != 2 and source_side != 4):
        return -1
    if gap < 1 or gap > 8 or target_side > gap or source_side > gap:
        return -1
    if brightness < 0 or brightness > 4 or reflectance < 0 or reflectance > 1:
        return -1
    if bound < 0 or bound > 1 or depth_value < 0 or depth_value > Float64(MAX_DEPTH):
        return -1
    if Float64(Int(depth_value)) != depth_value:
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 3:
        return -2

    var transfer = Float64(0)
    var leaves = 0
    var deepest = 0
    splash2_radiosity_visit(tx, ty, target_side, sx, sy, source_side, gap, bound,
        Int(depth_value), 0, 1.0, transfer, leaves, deepest)
    output[0] = reflectance * brightness * transfer
    output[1] = Float64(leaves)
    output[2] = Float64(deepest)
    return 3
