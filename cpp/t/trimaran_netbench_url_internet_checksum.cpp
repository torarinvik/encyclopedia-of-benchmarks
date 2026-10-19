/* Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t trimaran_netbench_url_internet_checksum(
    const std::int64_t *values, std::size_t length) noexcept {
    constexpr std::size_t max_bytes = 64;
    if (values == nullptr || length < 2 || length > max_bytes + 2) return -1;
    const auto mode = values[0], count_value = values[1];
    if ((mode != 0 && mode != 1) || count_value < 0 ||
        count_value > static_cast<std::int64_t>(max_bytes) ||
        length != static_cast<std::size_t>(count_value) + 2) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t i = 0; i < count; ++i)
        if (values[i + 2] < 0 || values[i + 2] > 255) return -1;
    std::uint64_t sum = 0;
    std::size_t i = 0;
    for (; i + 1 < count; i += 2) {
        const auto word = static_cast<std::uint64_t>(values[i + 2]) |
                          (static_cast<std::uint64_t>(values[i + 3]) << 8);
        sum -= word + 1;
    }
    if (i < count) sum += static_cast<std::uint64_t>(values[i + 2]);
    while ((sum >> 16) != 0) sum = (sum & 0xffffU) + (sum >> 16);
    if (mode == 1) sum = ((sum >> 8) | ((sum << 8) & 0xff00U)) & 0xffffU;
    return static_cast<std::int64_t>(sum);
}
