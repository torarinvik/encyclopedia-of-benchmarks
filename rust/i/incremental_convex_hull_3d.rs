/// Exact incremental 3D convex hull volume for general-position points.
const POINT_CAPACITY: usize = 6;
const FACE_CAPACITY: usize = 64;
const EDGE_CAPACITY: usize = 3 * FACE_CAPACITY;

fn side_of_face(points: &[i64], a: usize, b: usize, c: usize, point: usize) -> i64 {
    let abx = points[3 * b] - points[3 * a];
    let aby = points[3 * b + 1] - points[3 * a + 1];
    let abz = points[3 * b + 2] - points[3 * a + 2];
    let acx = points[3 * c] - points[3 * a];
    let acy = points[3 * c + 1] - points[3 * a + 1];
    let acz = points[3 * c + 2] - points[3 * a + 2];
    let apx = points[3 * point] - points[3 * a];
    let apy = points[3 * point + 1] - points[3 * a + 1];
    let apz = points[3 * point + 2] - points[3 * a + 2];
    (aby * acz - abz * acy) * apx
        + (abz * acx - abx * acz) * apy
        + (abx * acy - aby * acx) * apz
}

fn center_side(points: &[i64], a: usize, b: usize, c: usize, center_sum: &[i64; 3]) -> i64 {
    let abx = points[3 * b] - points[3 * a];
    let aby = points[3 * b + 1] - points[3 * a + 1];
    let abz = points[3 * b + 2] - points[3 * a + 2];
    let acx = points[3 * c] - points[3 * a];
    let acy = points[3 * c + 1] - points[3 * a + 1];
    let acz = points[3 * c + 2] - points[3 * a + 2];
    let dx = center_sum[0] - 4 * points[3 * a];
    let dy = center_sum[1] - 4 * points[3 * a + 1];
    let dz = center_sum[2] - 4 * points[3 * a + 2];
    (aby * acz - abz * acy) * dx
        + (abz * acx - abx * acz) * dy
        + (abx * acy - aby * acx) * dz
}

fn origin_determinant(points: &[i64], a: usize, b: usize, c: usize) -> i64 {
    let ax = points[3 * a];
    let ay = points[3 * a + 1];
    let az = points[3 * a + 2];
    let bx = points[3 * b];
    let by = points[3 * b + 1];
    let bz = points[3 * b + 2];
    let cx = points[3 * c];
    let cy = points[3 * c + 1];
    let cz = points[3 * c + 2];
    ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz) + az * (bx * cy - by * cx)
}

#[no_mangle]
pub extern "C" fn incremental_convex_hull_3d(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=20).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if !(4..=POINT_CAPACITY as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 3 * n { return -1; }
    let mut points = [0i64; 3 * POINT_CAPACITY];
    for index in 0..3 * n {
        if !(-10..=10).contains(&values[index + 1]) { return -1; }
        points[index] = values[index + 1];
    }
    for i in 0..n {
        for j in i + 1..n {
            if points[3 * i] == points[3 * j] && points[3 * i + 1] == points[3 * j + 1]
                && points[3 * i + 2] == points[3 * j + 2] { return -1; }
        }
    }
    for i in 0..n { for j in i + 1..n { for k in j + 1..n { for ell in k + 1..n {
        if side_of_face(&points, i, j, k, ell) == 0 { return -1; }
    }}}}

    let mut center_sum = [0i64; 3];
    for i in 0..4 { for axis in 0..3 { center_sum[axis] += points[3 * i + axis]; }}
    let mut face_a = [0usize; FACE_CAPACITY];
    let mut face_b = [0usize; FACE_CAPACITY];
    let mut face_c = [0usize; FACE_CAPACITY];
    face_a[..4].copy_from_slice(&[0, 0, 0, 1]);
    face_b[..4].copy_from_slice(&[1, 3, 2, 3]);
    face_c[..4].copy_from_slice(&[2, 1, 3, 2]);
    let mut face_count = 4usize;
    for face in 0..face_count {
        if center_side(&points, face_a[face], face_b[face], face_c[face], &center_sum) > 0 {
            std::mem::swap(&mut face_b[face], &mut face_c[face]);
        }
    }

    for point in 4..n {
        let mut visible = [false; FACE_CAPACITY];
        let mut visible_count = 0usize;
        for face in 0..face_count {
            visible[face] = side_of_face(&points, face_a[face], face_b[face], face_c[face], point) > 0;
            if visible[face] { visible_count += 1; }
        }
        if visible_count == 0 { continue; }
        let mut edge_a = [0usize; EDGE_CAPACITY];
        let mut edge_b = [0usize; EDGE_CAPACITY];
        let mut edge_count = 0usize;
        for face in 0..face_count {
            if visible[face] {
                for (a, b) in [(face_a[face], face_b[face]), (face_b[face], face_c[face]),
                               (face_c[face], face_a[face])] {
                    edge_a[edge_count] = a;
                    edge_b[edge_count] = b;
                    edge_count += 1;
                }
            }
        }
        let mut next_a = [0usize; FACE_CAPACITY];
        let mut next_b = [0usize; FACE_CAPACITY];
        let mut next_c = [0usize; FACE_CAPACITY];
        let mut next_count = 0usize;
        for face in 0..face_count {
            if !visible[face] {
                next_a[next_count] = face_a[face];
                next_b[next_count] = face_b[face];
                next_c[next_count] = face_c[face];
                next_count += 1;
            }
        }
        for edge in 0..edge_count {
            let mut copies = 0usize;
            for other in 0..edge_count {
                if (edge_a[edge] == edge_a[other] && edge_b[edge] == edge_b[other])
                    || (edge_a[edge] == edge_b[other] && edge_b[edge] == edge_a[other]) {
                    copies += 1;
                }
            }
            if copies != 1 { continue; }
            if next_count >= FACE_CAPACITY { return -1; }
            let (a, mut b, mut c) = (edge_a[edge], edge_b[edge], point);
            if center_side(&points, a, b, c, &center_sum) > 0 { std::mem::swap(&mut b, &mut c); }
            next_a[next_count] = a;
            next_b[next_count] = b;
            next_c[next_count] = c;
            next_count += 1;
        }
        face_a[..next_count].copy_from_slice(&next_a[..next_count]);
        face_b[..next_count].copy_from_slice(&next_b[..next_count]);
        face_c[..next_count].copy_from_slice(&next_c[..next_count]);
        face_count = next_count;
    }

    (0..face_count).map(|face| origin_determinant(&points, face_a[face], face_b[face], face_c[face])).sum()
}
