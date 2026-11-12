#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_queries = 32;
constexpr std::size_t max_output_bytes = 8 * max_queries;

void write_i64_le(std::array<std::uint8_t, max_output_bytes> &output,
                  std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t circle_line_intersection_count(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > 101) return -1;
    const auto center_x = input[0], center_y = input[1], radius = input[2], query_value = input[3];
    if (center_x < -1000 || center_x > 1000 || center_y < -1000 || center_y > 1000 ||
        radius < 0 || radius > 1000 || query_value < 0 || query_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto query_count = static_cast<std::size_t>(query_value);
    if (length != 4 + 3 * query_count) return -1;

    std::array<std::int64_t, max_queries> a_values{}, b_values{}, c_values{};
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto a = input[4 + 3 * query], b = input[5 + 3 * query], c = input[6 + 3 * query];
        if (a < -100 || a > 100 || b < -100 || b > 100 || (a == 0 && b == 0) ||
            c < -200000 || c > 200000) return -1;
        a_values[query] = a;
        b_values[query] = b;
        c_values[query] = c;
    }
    const auto needed = 8 * query_count;
    if (needed > 0 && (output == nullptr || capacity < needed)) return -2;

    std::array<std::uint8_t, max_output_bytes> staged{};
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto a = a_values[query], b = b_values[query], c = c_values[query];
        const auto offset = a * center_x + b * center_y + c;
        const auto normal_squared = a * a + b * b;
        const auto discriminant = radius * radius * normal_squared - offset * offset;
        const std::int64_t count = discriminant > 0 ? 2 : (discriminant == 0 ? 1 : 0);
        write_i64_le(staged, 8 * query, count);
    }
    for (std::size_t byte = 0; byte < needed; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(needed);
}
