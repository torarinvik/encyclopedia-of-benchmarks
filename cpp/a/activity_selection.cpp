/* Count a maximum set of non-overlapping half-open activities. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t activity_selection(const std::int64_t *input,
                                             std::size_t length) noexcept
{
    if (input == nullptr || length == 0 || input[0] < 0 || input[0] > 64) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return -1;
    if (count == 0) return 0;
    std::array<std::int64_t, 64> starts{};
    std::array<std::int64_t, 64> finishes{};
    for (std::size_t index = 0; index < count; ++index) {
        starts[index] = input[1 + 2 * index];
        finishes[index] = input[2 + 2 * index];
        if (starts[index] > finishes[index]) return -1;
    }
    for (std::size_t index = 1; index < count; ++index) {
        const auto start = starts[index];
        const auto finish = finishes[index];
        auto position = index;
        while (position > 0 && (finishes[position - 1] > finish ||
               (finishes[position - 1] == finish && starts[position - 1] > start))) {
            starts[position] = starts[position - 1];
            finishes[position] = finishes[position - 1];
            --position;
        }
        starts[position] = start;
        finishes[position] = finish;
    }
    std::int64_t selected = 1;
    auto last_finish = finishes[0];
    for (std::size_t index = 1; index < count; ++index) {
        if (starts[index] >= last_finish) {
            ++selected;
            last_finish = finishes[index];
        }
    }
    return selected;
}
