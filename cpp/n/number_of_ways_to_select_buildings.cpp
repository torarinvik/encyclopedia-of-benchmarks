#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MAX_LENGTH = 4096; }

extern "C" std::int64_t number_of_ways_to_select_buildings(const std::int64_t *values, std::size_t length) noexcept {
    if (length == 0) return 0;
    if (values == nullptr || length > MAX_LENGTH) return -1;
    std::uint64_t different_bits = 0;
    std::uint32_t zeros = 0;
    std::uint32_t ones = 0;
    std::uint32_t zero_one = 0;
    std::uint32_t one_zero = 0;
    std::uint64_t ways = 0;
    for (std::size_t index = 0; index < length; ++index) {
        std::uint64_t byte = static_cast<std::uint64_t>(values[index]) ^ 48;
        different_bits |= byte;
        bool is_one = (byte & 1) != 0;
        ways += static_cast<std::uint64_t>((is_one ? one_zero : zero_one));
        zero_one += is_one ? zeros : 0;
        one_zero += is_one ? 0 : ones;
        zeros += is_one ? 0 : 1;
        ones += is_one ? 1 : 0;
    }
    if (different_bits > 1) return -1;
    return static_cast<std::int64_t>(ways);
}
