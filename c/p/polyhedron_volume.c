#include <stddef.h>
#include <stdint.h>

#define MAX_FACES 32
#define MAX_PARSEABLE_LENGTH 290
#define SCALE INT64_C(1000000)

typedef struct { int64_t x, y, z; } Point;

static int same(Point a, Point b) { return a.x == b.x && a.y == b.y && a.z == b.z; }
static Point subtract(Point a, Point b) { return (Point){a.x - b.x, a.y - b.y, a.z - b.z}; }
static Point cross(Point a, Point b) {
    return (Point){a.y * b.z - a.z * b.y,
                   a.z * b.x - a.x * b.z,
                   a.x * b.y - a.y * b.x};
}
static int64_t dot(Point a, Point b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
static int64_t determinant(Point a, Point b, Point c) { return dot(a, cross(b, c)); }
static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t polyhedron_volume(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    int64_t face_count_value = input[0];
    if (face_count_value < 4 || face_count_value > MAX_FACES) return -1;
    size_t face_count = (size_t)face_count_value;
    if (length != 1 + 9 * face_count) return -1;

    Point faces[MAX_FACES][3];
    for (size_t face = 0; face < face_count; ++face) {
        for (size_t corner = 0; corner < 3; ++corner) {
            size_t at = 1 + 9 * face + 3 * corner;
            faces[face][corner] = (Point){input[at], input[at + 1], input[at + 2]};
            Point p = faces[face][corner];
            if (p.x < -50 || p.x > 50 || p.y < -50 || p.y > 50 || p.z < -50 || p.z > 50)
                return -1;
        }
        Point ab = subtract(faces[face][1], faces[face][0]);
        Point ac = subtract(faces[face][2], faces[face][0]);
        Point area = cross(ab, ac);
        if (area.x == 0 && area.y == 0 && area.z == 0) return -1;
    }

    for (size_t face = 0; face < face_count; ++face) {
        for (size_t edge = 0; edge < 3; ++edge) {
            Point start = faces[face][edge];
            Point end = faces[face][(edge + 1) % 3];
            size_t same_count = 0, reverse_count = 0;
            for (size_t other_face = 0; other_face < face_count; ++other_face) {
                for (size_t other_edge = 0; other_edge < 3; ++other_edge) {
                    Point other_start = faces[other_face][other_edge];
                    Point other_end = faces[other_face][(other_edge + 1) % 3];
                    if (same(start, other_start) && same(end, other_end)) ++same_count;
                    if (same(start, other_end) && same(end, other_start)) ++reverse_count;
                }
            }
            if (same_count != 1 || reverse_count != 1) return -1;
        }
    }

    int64_t determinant_sum = 0;
    for (size_t face = 0; face < face_count; ++face)
        determinant_sum += determinant(faces[face][0], faces[face][1], faces[face][2]);
    int64_t sign = determinant_sum < 0 ? -1 : 1;
    uint64_t scaled = (uint64_t)(determinant_sum < 0 ? -determinant_sum : determinant_sum) * (uint64_t)SCALE;
    uint64_t quotient = scaled / 6U;
    uint64_t remainder = scaled % 6U;
    if (2U * remainder >= 6U) ++quotient;
    int64_t result = sign * (int64_t)quotient;
    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, 0, result);
    return 8;
}
