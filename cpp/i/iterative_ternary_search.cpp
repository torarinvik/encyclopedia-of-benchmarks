/* Port of TheAlgorithms/Java IterativeTernarySearch interval updates. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t iterative_ternary_search(const std::int64_t *packed,
                                                  std::size_t length) noexcept
{
    if (length < 2) return -1;
    const std::int64_t target = packed[0];
    const std::int64_t *array = packed + 1;
    const std::size_t array_length = length - 1;
    if (array_length == 1) return array[0] == target ? 0 : -1;

    std::size_t left = 0;
    std::size_t right = array_length - 1;
    while (right > left) {
        if (array[left] == target) return static_cast<std::int64_t>(left);
        if (array[right] == target) return static_cast<std::int64_t>(right);
        const std::size_t left_third = left + (right - left) / 3 + 1;
        const std::size_t right_third = right - (right - left) / 3 - 1;
        if (array[left_third] <= target) left = left_third;
        else right = right_third;
    }
    return -1;
}
