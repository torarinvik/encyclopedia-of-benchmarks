// Source-ordered Binet formula, rounded to float then truncated to int.
#include <cmath>
#include <cstdint>

extern "C" std::int64_t fibonacci_formula(std::int64_t input)
{
    if (input < 0 || input > 35) return -1;
    const unsigned int n = static_cast<unsigned int>(input);
    const float seq = static_cast<float>((1 / std::sqrt(5) * std::pow(((1 + std::sqrt(5)) / 2), n + 1))
              - (1 / std::sqrt(5) * std::pow(((1 - std::sqrt(5)) / 2), n + 1));
    return static_cast<std::int32_t>(seq);
}
