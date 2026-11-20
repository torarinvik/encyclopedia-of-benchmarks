/* Exact incremental 3D convex hull volume for general-position points. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define POINT_CAPACITY 6
#define FACE_CAPACITY 64
#define EDGE_CAPACITY (3 * FACE_CAPACITY)

static int64_t side_of_face(const int64_t *points, size_t a, size_t b,
                            size_t c, size_t point)
{
    const int64_t abx = points[3 * b] - points[3 * a];
    const int64_t aby = points[3 * b + 1] - points[3 * a + 1];
    const int64_t abz = points[3 * b + 2] - points[3 * a + 2];
    const int64_t acx = points[3 * c] - points[3 * a];
    const int64_t acy = points[3 * c + 1] - points[3 * a + 1];
    const int64_t acz = points[3 * c + 2] - points[3 * a + 2];
    const int64_t apx = points[3 * point] - points[3 * a];
    const int64_t apy = points[3 * point + 1] - points[3 * a + 1];
    const int64_t apz = points[3 * point + 2] - points[3 * a + 2];
    return (aby * acz - abz * acy) * apx
         + (abz * acx - abx * acz) * apy
         + (abx * acy - aby * acx) * apz;
}

static int64_t center_side(const int64_t *points, size_t a, size_t b,
                           size_t c, const int64_t center_sum[3])
{
    const int64_t abx = points[3 * b] - points[3 * a];
    const int64_t aby = points[3 * b + 1] - points[3 * a + 1];
    const int64_t abz = points[3 * b + 2] - points[3 * a + 2];
    const int64_t acx = points[3 * c] - points[3 * a];
    const int64_t acy = points[3 * c + 1] - points[3 * a + 1];
    const int64_t acz = points[3 * c + 2] - points[3 * a + 2];
    const int64_t dx = center_sum[0] - 4 * points[3 * a];
    const int64_t dy = center_sum[1] - 4 * points[3 * a + 1];
    const int64_t dz = center_sum[2] - 4 * points[3 * a + 2];
    return (aby * acz - abz * acy) * dx
         + (abz * acx - abx * acz) * dy
         + (abx * acy - aby * acx) * dz;
}

static int64_t origin_determinant(const int64_t *points, size_t a,
                                  size_t b, size_t c)
{
    const int64_t ax = points[3 * a], ay = points[3 * a + 1], az = points[3 * a + 2];
    const int64_t bx = points[3 * b], by = points[3 * b + 1], bz = points[3 * b + 2];
    const int64_t cx = points[3 * c], cy = points[3 * c + 1], cz = points[3 * c + 2];
    return ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz)
         + az * (bx * cy - by * cx);
}

int64_t incremental_convex_hull_3d(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 20) return -1;
    const int64_t n_value = input[0];
    if (n_value < 4 || n_value > POINT_CAPACITY
        || length != 1 + 3 * (size_t)n_value) return -1;
    const size_t n = (size_t)n_value;
    int64_t points[3 * POINT_CAPACITY] = {0};
    for (size_t i = 0; i < 3 * n; ++i) {
        if (input[i + 1] < -10 || input[i + 1] > 10) return -1;
        points[i] = input[i + 1];
    }
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 1; j < n; ++j) {
            if (points[3 * i] == points[3 * j]
                && points[3 * i + 1] == points[3 * j + 1]
                && points[3 * i + 2] == points[3 * j + 2]) return -1;
        }
    }
    for (size_t i = 0; i < n; ++i) for (size_t j = i + 1; j < n; ++j)
        for (size_t k = j + 1; k < n; ++k) for (size_t ell = k + 1; ell < n; ++ell)
            if (side_of_face(points, i, j, k, ell) == 0) return -1;

    int64_t center_sum[3] = {0, 0, 0};
    for (size_t i = 0; i < 4; ++i) for (size_t axis = 0; axis < 3; ++axis)
        center_sum[axis] += points[3 * i + axis];
    size_t face_a[FACE_CAPACITY] = {0, 0, 0, 1};
    size_t face_b[FACE_CAPACITY] = {1, 3, 2, 3};
    size_t face_c[FACE_CAPACITY] = {2, 1, 3, 2};
    size_t face_count = 4;
    for (size_t face = 0; face < face_count; ++face) {
        if (center_side(points, face_a[face], face_b[face], face_c[face], center_sum) > 0) {
            const size_t temporary = face_b[face];
            face_b[face] = face_c[face];
            face_c[face] = temporary;
        }
    }

    for (size_t point = 4; point < n; ++point) {
        bool visible[FACE_CAPACITY] = {false};
        size_t visible_count = 0;
        for (size_t face = 0; face < face_count; ++face) {
            visible[face] = side_of_face(points, face_a[face], face_b[face],
                                         face_c[face], point) > 0;
            visible_count += visible[face] ? 1 : 0;
        }
        if (visible_count == 0) continue;

        size_t edge_a[EDGE_CAPACITY], edge_b[EDGE_CAPACITY];
        size_t edge_count = 0;
        for (size_t face = 0; face < face_count; ++face) if (visible[face]) {
            edge_a[edge_count] = face_a[face]; edge_b[edge_count++] = face_b[face];
            edge_a[edge_count] = face_b[face]; edge_b[edge_count++] = face_c[face];
            edge_a[edge_count] = face_c[face]; edge_b[edge_count++] = face_a[face];
        }
        size_t next_a[FACE_CAPACITY], next_b[FACE_CAPACITY], next_c[FACE_CAPACITY];
        size_t next_count = 0;
        for (size_t face = 0; face < face_count; ++face) if (!visible[face]) {
            next_a[next_count] = face_a[face];
            next_b[next_count] = face_b[face];
            next_c[next_count++] = face_c[face];
        }
        for (size_t edge = 0; edge < edge_count; ++edge) {
            size_t copies = 0;
            for (size_t other = 0; other < edge_count; ++other) {
                if ((edge_a[edge] == edge_a[other] && edge_b[edge] == edge_b[other])
                    || (edge_a[edge] == edge_b[other] && edge_b[edge] == edge_a[other])) ++copies;
            }
            if (copies != 1) continue;
            if (next_count >= FACE_CAPACITY) return -1;
            size_t a = edge_a[edge], b = edge_b[edge], c = point;
            if (center_side(points, a, b, c, center_sum) > 0) {
                const size_t temporary = b; b = c; c = temporary;
            }
            next_a[next_count] = a; next_b[next_count] = b; next_c[next_count++] = c;
        }
        for (size_t face = 0; face < next_count; ++face) {
            face_a[face] = next_a[face];
            face_b[face] = next_b[face];
            face_c[face] = next_c[face];
        }
        face_count = next_count;
    }

    int64_t volume_six = 0;
    for (size_t face = 0; face < face_count; ++face)
        volume_six += origin_determinant(points, face_a[face], face_b[face], face_c[face]);
    return volume_six;
}
