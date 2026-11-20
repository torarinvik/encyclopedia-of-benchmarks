#include <cstddef>
#include <cstdint>

namespace {
int middle_point(int first, int second) noexcept {
    if (first == second) return -1;
    const int first_x = first % 3;
    const int first_y = first / 3;
    const int second_x = second % 3;
    const int second_y = second / 3;
    const int delta_x = second_x - first_x;
    const int delta_y = second_y - first_y;
    if (delta_x % 2 != 0 || delta_y % 2 != 0) return -1;
    const int middle = ((first_y + second_y) / 2) * 3 + (first_x + second_x) / 2;
    return middle == first || middle == second ? -1 : middle;
}

std::int64_t count_from(int last, std::uint16_t visited, int used, int target) noexcept {
    if (used == target) return 1;
    std::int64_t count = 0;
    for (int next = 0; next < 9; ++next) {
        const auto bit = static_cast<std::uint16_t>(1u << static_cast<unsigned>(next));
        if ((visited & bit) != 0) continue;
        const int middle = middle_point(last, next);
        if (middle >= 0 && (visited & static_cast<std::uint16_t>(1u << static_cast<unsigned>(middle))) == 0)
            continue;
        count += count_from(next, static_cast<std::uint16_t>(visited | bit), used + 1, target);
    }
    return count;
}
}

extern "C" std::int64_t android_unlock_pattern_count(const std::int64_t *input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length != 1) return -1;
    const auto target = input[0];
    if (target < 4 || target > 9) return -1;
    std::int64_t count = 0;
    for (int start = 0; start < 9; ++start)
        count += count_from(start, static_cast<std::uint16_t>(1u << static_cast<unsigned>(start)), 1,
                            static_cast<int>(target));
    return count;
}
