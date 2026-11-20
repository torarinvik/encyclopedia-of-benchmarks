package polyhedron_volume

import "core:c"

MAX_FACES :: 32
MAX_PARSEABLE_LENGTH :: 290
SCALE :: i64(1_000_000)

coordinate :: proc "contextless" (xyz: []i64, face, corner, axis: int) -> i64 {
    return xyz[9 * face + 3 * corner + axis]
}
edge_matches :: proc "contextless" (xyz: []i64, face, edge, other_face, other_edge: int, reverse: bool) -> bool {
    edge_end := (edge + 1) % 3
    other_end := (other_edge + 1) % 3
    other_start := other_edge
    other_finish := other_end
    if reverse { other_start = other_end; other_finish = other_edge }
    for axis := 0; axis < 3; axis += 1 {
        if coordinate(xyz, face, edge, axis) != coordinate(xyz, other_face, other_start, axis) do return false
        if coordinate(xyz, face, edge_end, axis) != coordinate(xyz, other_face, other_finish, axis) do return false
    }
    return true
}
store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
polyhedron_volume :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    face_count_value := input[0]
    if face_count_value < 4 || face_count_value > MAX_FACES do return -1
    face_count := int(face_count_value)
    if length != c.size_t(1 + 9 * face_count) do return -1

    xyz: [MAX_FACES * 9]i64
    for face := 0; face < face_count; face += 1 {
        for corner := 0; corner < 3; corner += 1 {
            for axis := 0; axis < 3; axis += 1 {
                value := input[1 + 9 * face + 3 * corner + axis]
                if value < -50 || value > 50 do return -1
                xyz[9 * face + 3 * corner + axis] = value
            }
        }
        ax := coordinate(xyz[:], face, 1, 0) - coordinate(xyz[:], face, 0, 0)
        ay := coordinate(xyz[:], face, 1, 1) - coordinate(xyz[:], face, 0, 1)
        az := coordinate(xyz[:], face, 1, 2) - coordinate(xyz[:], face, 0, 2)
        bx := coordinate(xyz[:], face, 2, 0) - coordinate(xyz[:], face, 0, 0)
        by := coordinate(xyz[:], face, 2, 1) - coordinate(xyz[:], face, 0, 1)
        bz := coordinate(xyz[:], face, 2, 2) - coordinate(xyz[:], face, 0, 2)
        nx, ny, nz := ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
        if nx == 0 && ny == 0 && nz == 0 do return -1
    }
    mesh := xyz[:face_count * 9]
    for face := 0; face < face_count; face += 1 {
        for edge := 0; edge < 3; edge += 1 {
            same_count, reverse_count := 0, 0
            for other_face := 0; other_face < face_count; other_face += 1 {
                for other_edge := 0; other_edge < 3; other_edge += 1 {
                    if edge_matches(mesh, face, edge, other_face, other_edge, false) { same_count += 1 }
                    if edge_matches(mesh, face, edge, other_face, other_edge, true) { reverse_count += 1 }
                }
            }
            if same_count != 1 || reverse_count != 1 do return -1
        }
    }

    determinant_sum: i64 = 0
    for face := 0; face < face_count; face += 1 {
        ax, ay, az := coordinate(mesh, face, 0, 0), coordinate(mesh, face, 0, 1), coordinate(mesh, face, 0, 2)
        bx, by, bz := coordinate(mesh, face, 1, 0), coordinate(mesh, face, 1, 1), coordinate(mesh, face, 1, 2)
        cx, cy, cz := coordinate(mesh, face, 2, 0), coordinate(mesh, face, 2, 1), coordinate(mesh, face, 2, 2)
        determinant_sum += ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz) + az * (bx * cy - by * cx)
    }
    sign := i64(1)
    if determinant_sum < 0 { sign = -1 }
    magnitude := u64(if determinant_sum < 0 { -determinant_sum } else { determinant_sum })
    scaled := magnitude * u64(SCALE)
    quotient := scaled / 6
    if 2 * (scaled % 6) >= 6 { quotient += 1 }
    result := sign * i64(quotient)
    if output == nil || capacity < 8 do return -2
    store_i64_le(output, result)
    return 8
}
