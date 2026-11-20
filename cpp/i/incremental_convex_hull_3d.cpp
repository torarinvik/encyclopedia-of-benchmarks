/* Exact incremental 3D convex hull volume for general-position points. */
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t point_capacity = 6;
constexpr std::size_t face_capacity = 64;
constexpr std::size_t edge_capacity = 3 * face_capacity;

std::int64_t side_of_face(const std::array<std::int64_t, 18>& points,
                          std::size_t a, std::size_t b, std::size_t c,
                          std::size_t point)
{
    const auto abx = points[3 * b] - points[3 * a];
    const auto aby = points[3 * b + 1] - points[3 * a + 1];
    const auto abz = points[3 * b + 2] - points[3 * a + 2];
    const auto acx = points[3 * c] - points[3 * a];
    const auto acy = points[3 * c + 1] - points[3 * a + 1];
    const auto acz = points[3 * c + 2] - points[3 * a + 2];
    const auto apx = points[3 * point] - points[3 * a];
    const auto apy = points[3 * point + 1] - points[3 * a + 1];
    const auto apz = points[3 * point + 2] - points[3 * a + 2];
    return (aby * acz - abz * acy) * apx
         + (abz * acx - abx * acz) * apy
         + (abx * acy - aby * acx) * apz;
}

std::int64_t center_side(const std::array<std::int64_t, 18>& points,
                         std::size_t a, std::size_t b, std::size_t c,
                         const std::array<std::int64_t, 3>& center_sum)
{
    const auto abx = points[3 * b] - points[3 * a];
    const auto aby = points[3 * b + 1] - points[3 * a + 1];
    const auto abz = points[3 * b + 2] - points[3 * a + 2];
    const auto acx = points[3 * c] - points[3 * a];
    const auto acy = points[3 * c + 1] - points[3 * a + 1];
    const auto acz = points[3 * c + 2] - points[3 * a + 2];
    const auto dx = center_sum[0] - 4 * points[3 * a];
    const auto dy = center_sum[1] - 4 * points[3 * a + 1];
    const auto dz = center_sum[2] - 4 * points[3 * a + 2];
    return (aby * acz - abz * acy) * dx
         + (abz * acx - abx * acz) * dy
         + (abx * acy - aby * acx) * dz;
}

std::int64_t origin_determinant(const std::array<std::int64_t, 18>& points,
                                std::size_t a, std::size_t b, std::size_t c)
{
    const auto ax = points[3 * a], ay = points[3 * a + 1], az = points[3 * a + 2];
    const auto bx = points[3 * b], by = points[3 * b + 1], bz = points[3 * b + 2];
    const auto cx = points[3 * c], cy = points[3 * c + 1], cz = points[3 * c + 2];
    return ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz)
         + az * (bx * cy - by * cx);
}
}

extern "C" std::int64_t incremental_convex_hull_3d(const std::int64_t *input,
                                                      std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > 20) return -1;
    if (input[0] < 4 || input[0] > static_cast<std::int64_t>(point_capacity)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * n) return -1;
    std::array<std::int64_t, 18> points{};
    for (std::size_t i = 0; i < 3 * n; ++i) {
        if (input[i + 1] < -10 || input[i + 1] > 10) return -1;
        points[i] = input[i + 1];
    }
    for (std::size_t i = 0; i < n; ++i) for (std::size_t j = i + 1; j < n; ++j)
        if (points[3 * i] == points[3 * j] && points[3 * i + 1] == points[3 * j + 1]
            && points[3 * i + 2] == points[3 * j + 2]) return -1;
    for (std::size_t i = 0; i < n; ++i) for (std::size_t j = i + 1; j < n; ++j)
        for (std::size_t k = j + 1; k < n; ++k) for (std::size_t ell = k + 1; ell < n; ++ell)
            if (side_of_face(points, i, j, k, ell) == 0) return -1;

    std::array<std::int64_t, 3> center_sum{};
    for (std::size_t i = 0; i < 4; ++i) for (std::size_t axis = 0; axis < 3; ++axis)
        center_sum[axis] += points[3 * i + axis];
    std::array<std::size_t, face_capacity> face_a{0, 0, 0, 1};
    std::array<std::size_t, face_capacity> face_b{1, 3, 2, 3};
    std::array<std::size_t, face_capacity> face_c{2, 1, 3, 2};
    std::size_t face_count = 4;
    for (std::size_t face = 0; face < face_count; ++face) {
        if (center_side(points, face_a[face], face_b[face], face_c[face], center_sum) > 0)
            std::swap(face_b[face], face_c[face]);
    }

    for (std::size_t point = 4; point < n; ++point) {
        std::array<bool, face_capacity> visible{};
        std::size_t visible_count = 0;
        for (std::size_t face = 0; face < face_count; ++face) {
            visible[face] = side_of_face(points, face_a[face], face_b[face], face_c[face], point) > 0;
            visible_count += visible[face] ? 1 : 0;
        }
        if (visible_count == 0) continue;
        std::array<std::size_t, edge_capacity> edge_a{}, edge_b{};
        std::size_t edge_count = 0;
        for (std::size_t face = 0; face < face_count; ++face) if (visible[face]) {
            edge_a[edge_count] = face_a[face]; edge_b[edge_count++] = face_b[face];
            edge_a[edge_count] = face_b[face]; edge_b[edge_count++] = face_c[face];
            edge_a[edge_count] = face_c[face]; edge_b[edge_count++] = face_a[face];
        }
        std::array<std::size_t, face_capacity> next_a{}, next_b{}, next_c{};
        std::size_t next_count = 0;
        for (std::size_t face = 0; face < face_count; ++face) if (!visible[face]) {
            next_a[next_count] = face_a[face]; next_b[next_count] = face_b[face];
            next_c[next_count++] = face_c[face];
        }
        for (std::size_t edge = 0; edge < edge_count; ++edge) {
            std::size_t copies = 0;
            for (std::size_t other = 0; other < edge_count; ++other)
                if ((edge_a[edge] == edge_a[other] && edge_b[edge] == edge_b[other])
                    || (edge_a[edge] == edge_b[other] && edge_b[edge] == edge_a[other])) ++copies;
            if (copies != 1) continue;
            if (next_count >= face_capacity) return -1;
            auto a = edge_a[edge], b = edge_b[edge], c = point;
            if (center_side(points, a, b, c, center_sum) > 0) std::swap(b, c);
            next_a[next_count] = a; next_b[next_count] = b; next_c[next_count++] = c;
        }
        for (std::size_t face = 0; face < next_count; ++face) {
            face_a[face] = next_a[face]; face_b[face] = next_b[face]; face_c[face] = next_c[face];
        }
        face_count = next_count;
    }

    std::int64_t volume_six = 0;
    for (std::size_t face = 0; face < face_count; ++face)
        volume_six += origin_determinant(points, face_a[face], face_b[face], face_c[face]);
    return volume_six;
}
