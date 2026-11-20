module polyhedron_volume;

const usz MAX_FACES = 32;
const usz MAX_PARSEABLE_LENGTH = 290;
const ulong SCALE = 1000000;

fn long coordinate(long* xyz, usz face, usz corner, usz axis) {
    return xyz[9 * face + 3 * corner + axis];
}
fn bool edge_matches(long* xyz, usz face, usz edge, usz other_face, usz other_edge, bool reverse) {
    usz end_corner = (edge + 1) % 3;
    usz other_end = (other_edge + 1) % 3;
    for (usz axis = 0; axis < 3; axis++) {
        long first = coordinate(xyz, face, edge, axis);
        long last = coordinate(xyz, face, end_corner, axis);
        long other_first = coordinate(xyz, other_face, reverse ? other_end : other_edge, axis);
        long other_last = coordinate(xyz, other_face, reverse ? other_edge : other_end, axis);
        if (first != other_first || last != other_last) return false;
    }
    return true;
}
fn void store_i64(char* output, usz offset, long value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long polyhedron_volume(long* input, usz length, char* output, usz capacity)
    @export("polyhedron_volume") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long face_count_value = input[0];
    if (face_count_value < 4 || face_count_value > (long)MAX_FACES) return -1;
    usz face_count = (usz)face_count_value;
    if (length != 1 + 9 * face_count) return -1;

    long[MAX_FACES * 9] xyz;
    for (usz face = 0; face < face_count; face++) {
        for (usz corner = 0; corner < 3; corner++) {
            for (usz axis = 0; axis < 3; axis++) {
                long value = input[1 + 9 * face + 3 * corner + axis];
                if (value < -50 || value > 50) return -1;
                xyz[9 * face + 3 * corner + axis] = value;
            }
        }
        long ax = coordinate(xyz, face, 1, 0) - coordinate(xyz, face, 0, 0);
        long ay = coordinate(xyz, face, 1, 1) - coordinate(xyz, face, 0, 1);
        long az = coordinate(xyz, face, 1, 2) - coordinate(xyz, face, 0, 2);
        long bx = coordinate(xyz, face, 2, 0) - coordinate(xyz, face, 0, 0);
        long by = coordinate(xyz, face, 2, 1) - coordinate(xyz, face, 0, 1);
        long bz = coordinate(xyz, face, 2, 2) - coordinate(xyz, face, 0, 2);
        long nx = ay * bz - az * by;
        long ny = az * bx - ax * bz;
        long nz = ax * by - ay * bx;
        if (nx == 0 && ny == 0 && nz == 0) return -1;
    }
    for (usz face = 0; face < face_count; face++) {
        for (usz edge = 0; edge < 3; edge++) {
            usz same_count = 0, reverse_count = 0;
            for (usz other_face = 0; other_face < face_count; other_face++) {
                for (usz other_edge = 0; other_edge < 3; other_edge++) {
                    if (edge_matches(xyz, face, edge, other_face, other_edge, false)) same_count++;
                    if (edge_matches(xyz, face, edge, other_face, other_edge, true)) reverse_count++;
                }
            }
            if (same_count != 1 || reverse_count != 1) return -1;
        }
    }

    long determinant_sum = 0;
    for (usz face = 0; face < face_count; face++) {
        long ax = coordinate(xyz, face, 0, 0), ay = coordinate(xyz, face, 0, 1), az = coordinate(xyz, face, 0, 2);
        long bx = coordinate(xyz, face, 1, 0), by = coordinate(xyz, face, 1, 1), bz = coordinate(xyz, face, 1, 2);
        long cx = coordinate(xyz, face, 2, 0), cy = coordinate(xyz, face, 2, 1), cz = coordinate(xyz, face, 2, 2);
        determinant_sum += ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz) + az * (bx * cy - by * cx);
    }
    long sign = determinant_sum < 0 ? -1 : 1;
    ulong magnitude = (ulong)(determinant_sum < 0 ? -determinant_sum : determinant_sum);
    ulong scaled = magnitude * SCALE;
    ulong quotient = scaled / 6;
    if (2 * (scaled % 6) >= 6) quotient++;
    long result = sign * (long)quotient;
    if (output == null || capacity < 8) return -2;
    store_i64(output, 0, result);
    return 8;
}
