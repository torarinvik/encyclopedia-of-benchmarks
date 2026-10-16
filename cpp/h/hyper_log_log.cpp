#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_COUNT = 1024;
constexpr std::size_t REGISTER_COUNT = 65536;
}

extern "C" std::int64_t hyper_log_log(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_COUNT + 1) return -1;
    const std::int64_t count64 = input[0];
    if (count64 < 1 || count64 > static_cast<std::int64_t>(MAX_COUNT) || length != static_cast<std::size_t>(count64) + 1) return -1;
    const std::size_t count = static_cast<std::size_t>(count64);
    for (std::size_t i = 0; i < count; ++i) if (input[1 + i] < 1 || input[1 + i] > 65535) return -1;

    std::uint8_t registers[REGISTER_COUNT]{};
    std::uint8_t seen[REGISTER_COUNT]{};
    std::uint16_t touched[MAX_COUNT]{};
    std::size_t touched_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = static_cast<std::uint32_t>(input[1 + i]);
        auto bits = value;
        std::uint8_t rank = 0;
        while ((bits & 1u) == 0u) { ++rank; bits >>= 1; }
        if (seen[value] == 0) { seen[value] = 1; touched[touched_count++] = static_cast<std::uint16_t>(value); }
        if (rank > registers[value]) registers[value] = rank;
    }

    double z = 0.0;
    for (std::size_t i = 0; i < touched_count; ++i) z += 1.0 / static_cast<double>(1u << registers[touched[i]]);
    const double k = static_cast<double>(touched_count);
    return static_cast<std::int64_t>(std::ceil(0.673 * k * (k / z)));
}
