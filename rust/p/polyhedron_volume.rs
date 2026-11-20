const MAX_FACES: usize = 32;
const MAX_PARSEABLE_LENGTH: usize = 290;
const SCALE: u64 = 1_000_000;

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64, z: i64 }

fn same(a: Point, b: Point) -> bool { a.x == b.x && a.y == b.y && a.z == b.z }
fn subtract(a: Point, b: Point) -> Point { Point { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z } }
fn cross(a: Point, b: Point) -> Point {
    Point { x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x }
}
fn dot(a: Point, b: Point) -> i64 { a.x * b.x + a.y * b.y + a.z * b.z }
fn edge_matches(faces: &[Point], face: usize, edge: usize,
                other_face: usize, other_edge: usize, reverse: bool) -> bool {
    let edge_end = (edge + 1) % 3;
    let other_end = (other_edge + 1) % 3;
    let other_start = if reverse { other_end } else { other_edge };
    let other_finish = if reverse { other_edge } else { other_end };
    same(faces[3 * face + edge], faces[3 * other_face + other_start])
        && same(faces[3 * face + edge_end], faces[3 * other_face + other_finish])
}
fn round_micro(numerator: i64) -> i64 {
    let sign = if numerator < 0 { -1 } else { 1 };
    let scaled = numerator.unsigned_abs() * SCALE;
    let mut quotient = scaled / 6;
    if 2 * (scaled % 6) >= 6 { quotient += 1; }
    sign * quotient as i64
}
fn store_i64_le(output: &mut [u8], value: i64) {
    output[..8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn polyhedron_volume(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let face_count_value = values[0];
    if !(4..=MAX_FACES as i64).contains(&face_count_value) { return -1; }
    let face_count = face_count_value as usize;
    if length != 1 + 9 * face_count { return -1; }

    let zero = Point { x: 0, y: 0, z: 0 };
    let mut faces = [zero; MAX_FACES * 3];
    for face in 0..face_count {
        for corner in 0..3 {
            let offset = 1 + 9 * face + 3 * corner;
            let point = Point { x: values[offset], y: values[offset + 1], z: values[offset + 2] };
            if !(-50..=50).contains(&point.x) || !(-50..=50).contains(&point.y)
                || !(-50..=50).contains(&point.z) { return -1; }
            faces[3 * face + corner] = point;
        }
        let ab = subtract(faces[3 * face + 1], faces[3 * face]);
        let ac = subtract(faces[3 * face + 2], faces[3 * face]);
        let normal = cross(ab, ac);
        if normal.x == 0 && normal.y == 0 && normal.z == 0 { return -1; }
    }
    for face in 0..face_count {
        for edge in 0..3 {
            let mut same_count = 0;
            let mut reverse_count = 0;
            for other_face in 0..face_count {
                for other_edge in 0..3 {
                    if edge_matches(&faces, face, edge, other_face, other_edge, false) { same_count += 1; }
                    if edge_matches(&faces, face, edge, other_face, other_edge, true) { reverse_count += 1; }
                }
            }
            if same_count != 1 || reverse_count != 1 { return -1; }
        }
    }

    let mut determinant_sum = 0_i64;
    for face in 0..face_count {
        determinant_sum += dot(faces[3 * face], cross(faces[3 * face + 1], faces[3 * face + 2]));
    }
    let result = round_micro(determinant_sum);
    if output.is_null() || capacity < 8 { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, 8);
    store_i64_le(bytes, result);
    8
}
