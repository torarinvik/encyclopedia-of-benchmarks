#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t sieve_limit = 1'000'000;
constexpr std::int64_t max_ordinal = 10'001;
constexpr std::size_t max_valid_input_length = 1;
constexpr std::size_t max_parseable_input_length = 2;
}

extern "C" std::int64_t euler_problem_7(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < max_valid_input_length || length > max_parseable_input_length) return -1;
    if (length != max_valid_input_length || input[0] < 1 || input[0] > max_ordinal) return -1;

    std::vector<std::uint8_t> composite(sieve_limit, 0);
    std::int64_t count = 0;
    for (std::size_t candidate = 2; candidate < sieve_limit; ++candidate) {
        if (composite[candidate] == 0) {
            ++count;
            if (count == input[0]) return static_cast<std::int64_t>(candidate);
            for (std::size_t multiple = candidate * 2; multiple < sieve_limit; multiple += candidate)
                composite[multiple] = 1;
        }
    }
    return -1;
}
