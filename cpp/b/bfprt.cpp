/* One-based kth-smallest selection with an in-place median-of-medians copy. */
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_SIZE = 1024;
constexpr std::int64_t INVALID = -2'147'483'649;

void swap_values(std::int32_t *values, std::size_t left, std::size_t right) noexcept {
    const auto temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

void insertion_sort(std::int32_t *values, std::size_t left, std::size_t right) noexcept {
    for (auto index = left + 1; index <= right; ++index) {
        auto cursor = index;
        while (cursor > left && values[cursor - 1] > values[cursor]) {
            swap_values(values, cursor - 1, cursor);
            --cursor;
        }
    }
}

std::int32_t select_bfprt(std::int32_t *values, std::size_t left, std::size_t right, std::size_t rank) noexcept;

std::int32_t median_of_medians(std::int32_t *values, std::size_t left, std::size_t right) noexcept {
    const auto count = right - left + 1;
    const auto groups = (count + 4) / 5;
    for (std::size_t group = 0; group < groups; ++group) {
        const auto group_left = left + group * 5;
        const auto group_right = std::min(right, group_left + 4);
        insertion_sort(values, group_left, group_right);
        const auto median = group_left + (group_right - group_left + 1) / 2;
        swap_values(values, left + group, median);
    }
    if (groups == 1) return values[left];
    return select_bfprt(values, left, left + groups - 1, left + groups / 2);
}

std::int32_t select_bfprt(std::int32_t *values, std::size_t left, std::size_t right, std::size_t rank) noexcept {
    while (left < right) {
        const auto pivot = median_of_medians(values, left, right);
        auto less = left;
        auto current = left;
        auto greater = right + 1;
        while (current < greater) {
            if (values[current] < pivot) {
                swap_values(values, less, current);
                ++less;
                ++current;
            } else if (values[current] > pivot) {
                --greater;
                swap_values(values, current, greater);
            } else {
                ++current;
            }
        }
        if (rank < less) right = less - 1;
        else if (rank >= greater) left = greater;
        else return values[rank];
    }
    return values[left];
}
}

extern "C" std::int64_t bfprt(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2) return INVALID;
    const auto count_value = input[0];
    const auto rank_value = input[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(MAX_SIZE)) return INVALID;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 2 || rank_value < 1 || rank_value > count_value) return INVALID;

    std::int32_t values[MAX_SIZE];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 2];
        if (value < std::numeric_limits<std::int32_t>::min()
                || value > std::numeric_limits<std::int32_t>::max()) return INVALID;
        values[index] = static_cast<std::int32_t>(value);
    }
    return select_bfprt(values, 0, count - 1, static_cast<std::size_t>(rank_value - 1));
}
