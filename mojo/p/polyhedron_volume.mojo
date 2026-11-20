from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_FACES = 32
const MAX_PARSEABLE_LENGTH = 290
const SCALE: Int64 = 1_000_000

fn coordinate(xyz: InlineArray[Int64, 288], face: Int, corner: Int, axis: Int) -> Int64:
    return xyz[9 * face + 3 * corner + axis]

fn edge_matches(xyz: InlineArray[Int64, 288], face: Int, edge: Int,
                other_face: Int, other_edge: Int, reverse: Bool) -> Bool:
    let edge_end = (edge + 1) % 3
    let other_end = (other_edge + 1) % 3
    let other_start = other_end if reverse else other_edge
    let other_finish = other_edge if reverse else other_end
    for axis in range(3):
        if coordinate(xyz, face, edge, axis) != coordinate(xyz, other_face, other_start, axis):
            return False
        if coordinate(xyz, face, edge_end, axis) != coordinate(xyz, other_face, other_finish, axis):
            return False
    return True

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("polyhedron_volume")
fn polyhedron_volume(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let face_count_value = input[0]
    if face_count_value < 4 or face_count_value > MAX_FACES:
        return -1
    let face_count = Int(face_count_value)
    if length != c_size_t(1 + 9 * face_count):
        return -1

    var xyz = InlineArray[Int64, 288](fill=0)
    for face in range(face_count):
        for corner in range(3):
            for axis in range(3):
                let value = input[1 + 9 * face + 3 * corner + axis]
                if value < -50 or value > 50:
                    return -1
                xyz[9 * face + 3 * corner + axis] = value
        let ax = coordinate(xyz, face, 1, 0) - coordinate(xyz, face, 0, 0)
        let ay = coordinate(xyz, face, 1, 1) - coordinate(xyz, face, 0, 1)
        let az = coordinate(xyz, face, 1, 2) - coordinate(xyz, face, 0, 2)
        let bx = coordinate(xyz, face, 2, 0) - coordinate(xyz, face, 0, 0)
        let by = coordinate(xyz, face, 2, 1) - coordinate(xyz, face, 0, 1)
        let bz = coordinate(xyz, face, 2, 2) - coordinate(xyz, face, 0, 2)
        if ay * bz - az * by == 0 and az * bx - ax * bz == 0 and ax * by - ay * bx == 0:
            return -1

    for face in range(face_count):
        for edge in range(3):
            var same_count = 0
            var reverse_count = 0
            for other_face in range(face_count):
                for other_edge in range(3):
                    if edge_matches(xyz, face, edge, other_face, other_edge, False):
                        same_count += 1
                    if edge_matches(xyz, face, edge, other_face, other_edge, True):
                        reverse_count += 1
            if same_count != 1 or reverse_count != 1:
                return -1

    var determinant_sum: Int64 = 0
    for face in range(face_count):
        let ax = coordinate(xyz, face, 0, 0)
        let ay = coordinate(xyz, face, 0, 1)
        let az = coordinate(xyz, face, 0, 2)
        let bx = coordinate(xyz, face, 1, 0)
        let by = coordinate(xyz, face, 1, 1)
        let bz = coordinate(xyz, face, 1, 2)
        let cx = coordinate(xyz, face, 2, 0)
        let cy = coordinate(xyz, face, 2, 1)
        let cz = coordinate(xyz, face, 2, 2)
        determinant_sum += ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz) + az * (bx * cy - by * cx)
    let sign: Int64 = -1 if determinant_sum < 0 else 1
    let magnitude = UInt64(-determinant_sum if determinant_sum < 0 else determinant_sum)
    let scaled = magnitude * UInt64(SCALE)
    var quotient = scaled // UInt64(6)
    if UInt64(2) * (scaled % UInt64(6)) >= UInt64(6):
        quotient += 1
    let result = sign * Int64(quotient)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    store_i64_le(output, result)
    return 8
