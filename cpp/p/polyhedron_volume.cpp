#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxFaces = 32;
constexpr std::size_t kMaxParseableLength = 290;
constexpr std::int64_t kScale = 1'000'000;
struct Point { std::int64_t x, y, z; };

bool same(Point a, Point b) noexcept { return a.x == b.x && a.y == b.y && a.z == b.z; }
Point subtract(Point a, Point b) noexcept { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
Point cross(Point a, Point b) noexcept {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
std::int64_t dot(Point a, Point b) noexcept { return a.x * b.x + a.y * b.y + a.z * b.z; }
std::int64_t determinant(Point a, Point b, Point c) noexcept { return dot(a, cross(b, c)); }
void store_i64_le(std::uint8_t* output, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t polyhedron_volume(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxParseableLength) return -1;
    const auto face_count_value = input[0];
    if (face_count_value < 4 || face_count_value > static_cast<std::int64_t>(kMaxFaces)) return -1;
    const auto face_count = static_cast<std::size_t>(face_count_value);
    if (length != 1 + 9 * face_count) return -1;

    std::array<std::array<Point, 3>, kMaxFaces> faces{};
    for (std::size_t face = 0; face < face_count; ++face) {
        for (std::size_t corner = 0; corner < 3; ++corner) {
            const auto at = 1 + 9 * face + 3 * corner;
            const Point p{input[at], input[at + 1], input[at + 2]};
            if (p.x < -50 || p.x > 50 || p.y < -50 || p.y > 50 || p.z < -50 || p.z > 50) return -1;
            faces[face][corner] = p;
        }
        const auto normal = cross(subtract(faces[face][1], faces[face][0]),
                                  subtract(faces[face][2], faces[face][0]));
        if (normal.x == 0 && normal.y == 0 && normal.z == 0) return -1;
    }
    for (std::size_t face = 0; face < face_count; ++face) {
        for (std::size_t edge = 0; edge < 3; ++edge) {
            const auto start = faces[face][edge];
            const auto end = faces[face][(edge + 1) % 3];
            std::size_t same_count = 0, reverse_count = 0;
            for (std::size_t other_face = 0; other_face < face_count; ++other_face) {
                for (std::size_t other_edge = 0; other_edge < 3; ++other_edge) {
                    const auto other_start = faces[other_face][other_edge];
                    const auto other_end = faces[other_face][(other_edge + 1) % 3];
                    if (same(start, other_start) && same(end, other_end)) ++same_count;
                    if (same(start, other_end) && same(end, other_start)) ++reverse_count;
                }
            }
            if (same_count != 1 || reverse_count != 1) return -1;
        }
    }

    std::int64_t determinant_sum = 0;
    for (std::size_t face = 0; face < face_count; ++face)
        determinant_sum += determinant(faces[face][0], faces[face][1], faces[face][2]);
    const auto sign = determinant_sum < 0 ? -1 : 1;
    const auto magnitude = static_cast<std::uint64_t>(determinant_sum < 0 ? -determinant_sum : determinant_sum);
    const auto scaled = magnitude * static_cast<std::uint64_t>(kScale);
    auto quotient = scaled / 6U;
    if (2U * (scaled % 6U) >= 6U) ++quotient;
    const auto result = sign * static_cast<std::int64_t>(quotient);
    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, result);
    return 8;
}
