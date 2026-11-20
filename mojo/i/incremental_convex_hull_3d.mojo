from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn side_of_face(input: UnsafePointer[Int64, ImmutAnyOrigin], a: Int, b: Int, c: Int, point: Int) -> Int64:
    let abx = input[1 + 3*b] - input[1 + 3*a]
    let aby = input[1 + 3*b + 1] - input[1 + 3*a + 1]
    let abz = input[1 + 3*b + 2] - input[1 + 3*a + 2]
    let acx = input[1 + 3*c] - input[1 + 3*a]
    let acy = input[1 + 3*c + 1] - input[1 + 3*a + 1]
    let acz = input[1 + 3*c + 2] - input[1 + 3*a + 2]
    let apx = input[1 + 3*point] - input[1 + 3*a]
    let apy = input[1 + 3*point + 1] - input[1 + 3*a + 1]
    let apz = input[1 + 3*point + 2] - input[1 + 3*a + 2]
    return (aby*acz-abz*acy)*apx + (abz*acx-abx*acz)*apy + (abx*acy-aby*acx)*apz

fn center_side(input: UnsafePointer[Int64, ImmutAnyOrigin], a: Int, b: Int, c: Int,
               center_sum: InlineArray[Int64, 3]) -> Int64:
    let abx = input[1 + 3*b] - input[1 + 3*a]
    let aby = input[1 + 3*b + 1] - input[1 + 3*a + 1]
    let abz = input[1 + 3*b + 2] - input[1 + 3*a + 2]
    let acx = input[1 + 3*c] - input[1 + 3*a]
    let acy = input[1 + 3*c + 1] - input[1 + 3*a + 1]
    let acz = input[1 + 3*c + 2] - input[1 + 3*a + 2]
    let dx = center_sum[0] - 4*input[1 + 3*a]
    let dy = center_sum[1] - 4*input[1 + 3*a + 1]
    let dz = center_sum[2] - 4*input[1 + 3*a + 2]
    return (aby*acz-abz*acy)*dx + (abz*acx-abx*acz)*dy + (abx*acy-aby*acx)*dz

fn origin_determinant(input: UnsafePointer[Int64, ImmutAnyOrigin], a: Int, b: Int, c: Int) -> Int64:
    let ax=input[1+3*a]; let ay=input[1+3*a+1]; let az=input[1+3*a+2]
    let bx=input[1+3*b]; let by=input[1+3*b+1]; let bz=input[1+3*b+2]
    let cx=input[1+3*c]; let cy=input[1+3*c+1]; let cz=input[1+3*c+2]
    return ax*(by*cz-bz*cy) + ay*(bz*cx-bx*cz) + az*(bx*cy-by*cx)

@export("incremental_convex_hull_3d")
fn incremental_convex_hull_3d(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 20: return -1
    let n_value = input[0]
    if n_value < 4 or n_value > 6: return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 3*n): return -1
    for i in range(3*n):
        if input[i+1] < -10 or input[i+1] > 10: return -1
    for i in range(n):
        for j in range(i+1, n):
            if input[1+3*i] == input[1+3*j] and input[1+3*i+1] == input[1+3*j+1]
                and input[1+3*i+2] == input[1+3*j+2]: return -1
    for i in range(n):
        for j in range(i+1, n):
            for k in range(j+1, n):
                for ell in range(k+1, n):
                    if side_of_face(input, i, j, k, ell) == 0: return -1

    var center_sum = InlineArray[Int64, 3](fill=0)
    for i in range(4):
        for axis in range(3): center_sum[axis] += input[1 + 3*i + axis]
    var face_a = InlineArray[Int, 64](fill=0)
    var face_b = InlineArray[Int, 64](fill=0)
    var face_c = InlineArray[Int, 64](fill=0)
    face_a[0] = 0; face_a[1] = 0; face_a[2] = 0; face_a[3] = 1
    face_b[0] = 1; face_b[1] = 3; face_b[2] = 2; face_b[3] = 3
    face_c[0] = 2; face_c[1] = 1; face_c[2] = 3; face_c[3] = 2
    var face_count = 4
    for f in range(face_count):
        if center_side(input, face_a[f], face_b[f], face_c[f], center_sum) > 0:
            let temporary = face_b[f]
            face_b[f] = face_c[f]
            face_c[f] = temporary

    for point in range(4, n):
        var visible = InlineArray[Bool, 64](fill=False)
        var visible_count = 0
        for f in range(face_count):
            visible[f] = side_of_face(input, face_a[f], face_b[f], face_c[f], point) > 0
            if visible[f]: visible_count += 1
        if visible_count == 0: continue
        var edge_a = InlineArray[Int, 192](fill=0)
        var edge_b = InlineArray[Int, 192](fill=0)
        var edge_count = 0
        for f in range(face_count):
            if visible[f]:
                edge_a[edge_count] = face_a[f]; edge_b[edge_count] = face_b[f]; edge_count += 1
                edge_a[edge_count] = face_b[f]; edge_b[edge_count] = face_c[f]; edge_count += 1
                edge_a[edge_count] = face_c[f]; edge_b[edge_count] = face_a[f]; edge_count += 1
        var next_a = InlineArray[Int, 64](fill=0)
        var next_b = InlineArray[Int, 64](fill=0)
        var next_c = InlineArray[Int, 64](fill=0)
        var next_count = 0
        for f in range(face_count):
            if not visible[f]:
                next_a[next_count] = face_a[f]; next_b[next_count] = face_b[f]
                next_c[next_count] = face_c[f]; next_count += 1
        for edge in range(edge_count):
            var copies = 0
            for other in range(edge_count):
                if (edge_a[edge] == edge_a[other] and edge_b[edge] == edge_b[other])
                    or (edge_a[edge] == edge_b[other] and edge_b[edge] == edge_a[other]): copies += 1
            if copies != 1: continue
            if next_count >= 64: return -1
            let a = edge_a[edge]
            var b = edge_b[edge]
            var c = point
            if center_side(input, a, b, c, center_sum) > 0:
                let temporary = b
                b = c
                c = temporary
            next_a[next_count] = a; next_b[next_count] = b; next_c[next_count] = c; next_count += 1
        for f in range(next_count):
            face_a[f] = next_a[f]; face_b[f] = next_b[f]; face_c[f] = next_c[f]
        face_count = next_count

    var volume_six: Int64 = 0
    for f in range(face_count): volume_six += origin_determinant(input, face_a[f], face_b[f], face_c[f])
    return volume_six
