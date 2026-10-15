// Preserve the digit-window recurrence used by the pinned C# checker.
#include <cstdint>
#include <vector>

extern "C" std::int64_t keith_number_checker(std::int64_t number) noexcept
{
    if (number < 2 || number > 1000) return -1;
    const std::int64_t original = number;
    std::int64_t temp = number;
    std::int64_t digits = 0;
    while (temp != 0) {
        ++digits;
        temp /= 10;
    }

    std::vector<std::int64_t> terms(static_cast<std::size_t>(number), 0);
    temp = number;
    for (std::int64_t i = digits - 1; i >= 0; --i) {
        terms[static_cast<std::size_t>(i)] = temp % 10;
        temp /= 10;
    }

    std::int64_t sum = 0;
    std::int64_t k = digits;
    while (sum < original) {
        sum = 0;
        for (std::int64_t j = 1; j <= digits; ++j) sum += terms[static_cast<std::size_t>(k - j)];
        terms[static_cast<std::size_t>(k++)] = sum;
    }
    return sum == original ? 1 : 0;
}
