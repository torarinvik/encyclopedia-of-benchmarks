# Copyright (C) 1996 McGill University.
# Copyright (C) 1996 McCAT System Group.
# Copyright (C) 1996 ACAPS Benchmark Administrator, benadmin@acaps.cs.mcgill.ca.
# Independent bounded transform profile; source notice is in the package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import ceil, cos, floor, sin
from std.memory import ImmutAnyOrigin, UnsafePointer

fn scene_identity() -> InlineArray[Float64, 16]:
    var result = InlineArray[Float64, 16](fill=0.0)
    for i in range(4): result[5 * i] = 1.0
    return result

fn scene_multiply(a: InlineArray[Float64, 16], b: InlineArray[Float64, 16]) -> InlineArray[Float64, 16]:
    var result = InlineArray[Float64, 16](fill=0.0)
    for row in range(4):
        for col in range(4):
            for k in range(4): result[4 * row + col] += a[4 * row + k] * b[4 * k + col]
    return result

fn scene_rotation(rx: Float64, ry: Float64, rz: Float64) -> InlineArray[Float64, 16]:
    let radians: Float64 = 3.14159265359 / 180.0
    let cx = cos(radians * rx)
    let sx = sin(radians * rx)
    let cy = cos(radians * ry)
    let sy = sin(radians * ry)
    let cz = cos(radians * rz)
    let sz = sin(radians * rz)
    var mx = scene_identity()
    var my = scene_identity()
    var mz = scene_identity()
    mx[5] = cx
    mx[6] = -sx
    mx[9] = sx
    mx[10] = cx
    my[0] = cy
    my[2] = sy
    my[8] = -sy
    my[10] = cy
    mz[0] = cz
    mz[1] = -sz
    mz[4] = sz
    mz[5] = cz
    return scene_multiply(scene_multiply(mx, my), mz)

fn scene_apply(matrix: InlineArray[Float64, 16], point: InlineArray[Float64, 3]) -> InlineArray[Float64, 3]:
    var result = InlineArray[Float64, 3](fill=0.0)
    for row in range(3):
        result[row] = point[0] * matrix[4 * row] + point[1] * matrix[4 * row + 1] + point[2] * matrix[4 * row + 2] + matrix[4 * row + 3]
    return result

fn scene_matrices(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int, rotation_y_offset: Int) -> (InlineArray[Float64, 16], InlineArray[Float64, 16], InlineArray[Float64, 16]):
    var scale = scene_identity()
    var translation = scene_identity()
    for axis in range(3):
        scale[5 * axis] = Float64(input[offset + axis]) / 1000000.0
        translation[4 * axis + 3] = Float64(input[offset + 6 + axis]) / 1000000.0
    let rotation = scene_rotation(Float64(input[offset + 3]) / 1000000.0,
                                  Float64(input[offset + 4]) / 1000000.0 + Float64(rotation_y_offset),
                                  Float64(input[offset + 5]) / 1000000.0)
    return (scale, rotation, translation)

fn scene_round(value: Float64) -> Int64:
    let scaled = value * 1000.0
    return Int64(floor(scaled + 0.5)) if scaled >= 0.0 else Int64(ceil(scaled - 0.5))

@export("mccat_08_main")
fn mccat_08_main(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 20 or length > 68: return -1
    let raw_frames = input[0]
    let raw_points = input[1]
    if raw_frames < 1 or raw_frames > 360 or raw_points < 1 or raw_points > 16: return -1
    let frames = Int(raw_frames)
    let count = Int(raw_points)
    if Int(length) != 20 + 3 * count: return -1
    for group in range(2):
        let base = 2 + 9 * group
        for axis in range(3):
            if input[base + axis] < -4000000 or input[base + axis] > 4000000: return -1
            if input[base + 3 + axis] < -360000000 or input[base + 3 + axis] > 360000000: return -1
            if input[base + 6 + axis] < -100000000 or input[base + 6 + axis] > 100000000: return -1
    var raw = InlineArray[Int64, 48](fill=0)
    var points = InlineArray[Float64, 48](fill=0.0)
    var unique = 0
    for i in range(count):
        for axis in range(3):
            let value = input[20 + 3 * i + axis]
            if value < -100000000 or value > 100000000: return -1
        var duplicate = False
        for j in range(unique):
            if raw[3 * j] == input[20 + 3 * i] and raw[3 * j + 1] == input[21 + 3 * i] and raw[3 * j + 2] == input[22 + 3 * i]: duplicate = True
        if not duplicate:
            for axis in range(3):
                raw[3 * unique + axis] = input[20 + 3 * i + axis]
                points[3 * unique + axis] = Float64(raw[3 * unique + axis]) / 1000000.0
            unique += 1
    var checksum: Int64 = 0
    for frame in range(frames):
        let (child_scale, child_rotation, child_translation) = scene_matrices(input, 2, 0)
        let (parent_scale, parent_rotation, parent_translation) = scene_matrices(input, 11, frame)
        for i in range(unique):
            let point = InlineArray[Float64, 3](points[3 * i], points[3 * i + 1], points[3 * i + 2])
            let child = scene_apply(child_translation, scene_apply(child_rotation, scene_apply(child_scale, point)))
            let final_point = scene_apply(parent_translation, scene_apply(parent_rotation, scene_apply(parent_scale, child)))
            checksum += Int64((frame + 1) * (i + 1)) * (scene_round(final_point[0]) + 3 * scene_round(final_point[1]) + 7 * scene_round(final_point[2]))
    return checksum
