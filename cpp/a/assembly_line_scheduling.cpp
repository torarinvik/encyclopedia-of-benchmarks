/* Minimum time to cross two assembly lines using station-by-station dynamic programming. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t assembly_line_scheduling(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 7 || values[0] < 1 || values[0] > 64) return -1;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    if (length != 4 * n + 3) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 1000) return -1;

    const std::size_t a0 = 1;
    const std::size_t a1 = a0 + n;
    const std::size_t t0 = a1 + n;
    const std::size_t t1 = t0 + n - 1;
    const std::size_t entry = t1 + n - 1;
    std::int64_t line0 = values[entry] + values[a0];
    std::int64_t line1 = values[entry + 1] + values[a1];
    for (std::size_t station = 1; station < n; ++station) {
        const std::int64_t stay0 = line0 + values[a0 + station];
        const std::int64_t switch0 = line1 + values[t1 + station - 1] + values[a0 + station];
        const std::int64_t stay1 = line1 + values[a1 + station];
        const std::int64_t switch1 = line0 + values[t0 + station - 1] + values[a1 + station];
        line0 = stay0 < switch0 ? stay0 : switch0;
        line1 = stay1 < switch1 ? stay1 : switch1;
    }
    const std::int64_t total0 = line0 + values[entry + 2];
    const std::int64_t total1 = line1 + values[entry + 3];
    const std::int64_t answer = total0 < total1 ? total0 : total1;
    if (output == nullptr || output_capacity < 4) return -2;
    const std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(answer));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    return 4;
}
