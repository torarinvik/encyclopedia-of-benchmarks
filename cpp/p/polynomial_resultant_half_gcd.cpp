// Draft scalar entry point; implementation has not been compiled or run.
#include "polynomial_resultant_half_gcd_kernel.hpp"
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t polynomial_resultant_half_gcd(
    const std::int64_t* input, std::size_t length) {
    using namespace resultant_draft;
    if (input == nullptr || length < 4 || length > 100002) return -1;
    const auto m = input[0], n = input[1];
    if (m < 0 || m > 50000 || n < 0 || n > 50000 || m + n > 99998)
        return -1;
    const auto first_count = static_cast<std::size_t>(m) + 1;
    const auto second_count = static_cast<std::size_t>(n) + 1;
    if (length != 2 + first_count + second_count) return -1;
    for (std::size_t i = 2; i < length; ++i)
        if (input[i] < 0 || input[i] >= prime) return -1;
    if (input[1 + first_count] == 0 || input[length - 1] == 0) return -1;
    Poly a(input + 2, input + 2 + first_count);
    Poly b(input + 2 + first_count, input + length);
    return resultant(std::move(a), std::move(b));
}
