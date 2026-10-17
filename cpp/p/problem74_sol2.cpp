// Count sol2's bounded, source-ordered digit-factorial chains.
#include <cstdint>
#include <cstdlib>

namespace {
constexpr std::int64_t MAX_CHAIN_LENGTH = 60;
constexpr std::int64_t MAX_NUMBER_LIMIT = 1'000'000;
constexpr std::size_t PATH_CAPACITY = MAX_CHAIN_LENGTH + 1;
constexpr std::int64_t DIGIT_FACTORIALS[10] = {
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880
};

std::int64_t digit_factorial_sum(std::int64_t value) noexcept
{
    std::int64_t total = 0;
    do {
        total += DIGIT_FACTORIALS[value % 10];
        value /= 10;
    } while (value > 0);
    return total;
}

bool cache_contains(std::int64_t value, std::int64_t number_limit,
                    const std::uint32_t *cache) noexcept
{
    return value >= 1 && value < number_limit && cache[value] != 0;
}

bool path_contains(const std::int64_t *path, std::size_t path_length,
                   std::int64_t value) noexcept
{
    for (std::size_t index = 0; index < path_length; ++index)
        if (path[index] == value) return true;
    return false;
}
}

extern "C" std::int64_t problem74_sol2(std::int64_t chain_length,
                                         std::int64_t number_limit) noexcept
{
    if (chain_length < 1 || chain_length > MAX_CHAIN_LENGTH ||
        number_limit < 1 || number_limit > MAX_NUMBER_LIMIT) return -1;
    if (number_limit == 1) return 0;

    auto *cache = static_cast<std::uint32_t *>(
        std::calloc(static_cast<std::size_t>(number_limit), sizeof(std::uint32_t)));
    if (cache == nullptr) return -1;

    std::int64_t chains_counter = 0;
    for (std::int64_t start = 1; start < number_limit; ++start) {
        std::int64_t path[PATH_CAPACITY];
        std::size_t path_length = 0;
        std::int64_t chain_set_length = 0;
        std::int64_t chain_element = start;
        while (!cache_contains(chain_element, number_limit, cache) &&
               !path_contains(path, path_length, chain_element) &&
               chain_set_length <= chain_length) {
            path[path_length++] = chain_element;
            ++chain_set_length;
            chain_element = digit_factorial_sum(chain_element);
        }
        if (cache_contains(chain_element, number_limit, cache))
            chain_set_length += cache[chain_element];

        cache[start] = static_cast<std::uint32_t>(chain_set_length);
        if (chain_set_length == chain_length) ++chains_counter;
    }

    std::free(cache);
    return chains_counter;
}
