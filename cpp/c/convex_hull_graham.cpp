#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t kMaxPoints = 64;

std::int64_t cross(std::size_t a, std::size_t b, std::size_t c,
                   const std::int64_t* values) noexcept {
    const auto ax = values[2 * a], ay = values[2 * a + 1];
    const auto bx = values[2 * b], by = values[2 * b + 1];
    const auto cx = values[2 * c], cy = values[2 * c + 1];
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

int orientation(std::size_t a, std::size_t b, std::size_t c,
                const std::int64_t* values) noexcept {
    const auto turn = cross(a, b, c, values);
    return turn < 0 ? 1 : turn > 0 ? -1 : 0;
}

void put_index(std::uint8_t* output, std::size_t position, std::size_t id) noexcept {
    const auto value = static_cast<std::uint32_t>(id);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[4 * position + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t convex_hull_graham(const std::int64_t* values, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) noexcept {
    if (length % 2 != 0 || length > 2 * kMaxPoints || values == nullptr) return -1;
    const std::size_t count = length / 2;
    if (count < 3 || count > kMaxPoints) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < -2000 || values[index] > 2000) return -1;

    std::vector<std::size_t> order(count), upper, lower;
    for (std::size_t index = 0; index < count; ++index) order[index] = index;
    std::sort(order.begin(), order.end(), [values](std::size_t left, std::size_t right) {
        return values[2 * left] < values[2 * right];
    });
    for (std::size_t index = 1; index < count; ++index)
        if (values[2 * order[index - 1]] == values[2 * order[index]]) return -1;
    for (std::size_t index = 1; index + 1 < count; ++index)
        if (cross(order[0], order[index], order[count - 1], values) == 0) return -1;

    upper.reserve(count);
    lower.reserve(count);
    upper.push_back(0);
    lower.push_back(0);
    for (std::size_t index = 1; index < count; ++index) {
        const int turn = orientation(order[0], order[index], order[count - 1], values);
        if (index == count - 1 || turn != -1) {
            while (upper.size() >= 2 &&
                   orientation(order[upper[upper.size() - 2]], order[upper.back()], order[index], values) == -1)
                upper.pop_back();
            upper.push_back(index);
        }
        if (index == count - 1 || turn != 1) {
            while (lower.size() >= 2 &&
                   orientation(order[lower[lower.size() - 2]], order[lower.back()], order[index], values) == 1)
                lower.pop_back();
            lower.push_back(index);
        }
    }
    const std::size_t hull_count = upper.size() - 2 + lower.size();
    if (output == nullptr || capacity < 4 * hull_count) return -2;
    std::size_t written = 0;
    for (std::size_t index = 1; index + 1 < upper.size(); ++index)
        put_index(output, written++, order[upper[index]]);
    for (std::size_t index = lower.size(); index > 0; --index)
        put_index(output, written++, order[lower[index - 1]]);
    return static_cast<std::int64_t>(hull_count);
}
