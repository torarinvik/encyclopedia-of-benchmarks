#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TRACE_VALUES = 256;
constexpr std::int64_t MAX_KEY = 1'000'000'000;

void positions(std::int64_t value, unsigned &first, unsigned &second) noexcept
{
    first = static_cast<unsigned>((value * 17 + 3) % 64);
    second = static_cast<unsigned>((value * 31 + 7) % 64);
}
}

extern "C" std::int64_t bloom_filter(const std::int64_t *trace, std::size_t length,
                                      std::uint8_t *output,
                                      std::size_t output_capacity) noexcept
{
    if (length > MAX_TRACE_VALUES || length % 2 != 0 || (length != 0 && trace == nullptr)) return -1;
    std::size_t query_count = 0;
    for (std::size_t index = 0; index < length; index += 2) {
        const auto operation = trace[index];
        const auto key = trace[index + 1];
        if ((operation != 1 && operation != 2) || key < 0 || key > MAX_KEY) return -1;
        if (operation == 2) ++query_count;
    }
    if (output_capacity < query_count || (query_count != 0 && output == nullptr)) return -2;

    std::uint64_t bits = 0;
    std::size_t written = 0;
    for (std::size_t index = 0; index < length; index += 2) {
        unsigned first, second;
        positions(trace[index + 1], first, second);
        const std::uint64_t first_mask = std::uint64_t{1} << first;
        const std::uint64_t second_mask = std::uint64_t{1} << second;
        if (trace[index] == 1) {
            bits |= first_mask | second_mask;
        } else {
            output[written++] = static_cast<std::uint8_t>(
                (bits & first_mask) != 0 && (bits & second_mask) != 0);
        }
    }
    return static_cast<std::int64_t>(written);
}
