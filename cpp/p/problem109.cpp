#include <array>
#include <cstdint>

extern "C" std::int64_t problem109(std::int64_t limit) noexcept {
    std::array<std::int64_t, 63> values{};
    std::array<std::int64_t, 21> doubles{};
    std::size_t value_count = 0, double_count = 0;
    for (std::int64_t score = 1; score <= 20; ++score) values[value_count++] = score;
    values[value_count++] = 25;
    for (std::int64_t score = 1; score <= 20; ++score) { doubles[double_count++] = 2 * score; values[value_count++] = 2 * score; }
    doubles[double_count++] = 50; values[value_count++] = 50;
    for (std::int64_t score = 1; score <= 20; ++score) values[value_count++] = 3 * score;
    values[value_count++] = 0;
    std::int64_t count = 0;
    for (std::size_t d = 0; d < double_count; ++d)
        for (std::size_t first = 0; first < value_count; ++first)
            for (std::size_t second = first; second < value_count; ++second)
                count += doubles[d] + values[first] + values[second] < limit;
    return count;
}
