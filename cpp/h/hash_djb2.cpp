#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hash_djb2(const std::int64_t *input, std::size_t length)
{
    constexpr std::size_t max_bytes = 3;
    if (input == nullptr || length < 1 || length > max_bytes + 1) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_bytes) ||
        length != static_cast<std::size_t>(count_value) + 1) return -1;
    std::uint64_t hash = 5381;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count_value); ++index) {
        const std::int64_t byte = input[index + 1];
        if (byte < 1 || byte > 127) return -1;
        hash = hash * 33 + static_cast<std::uint64_t>(byte);
    }
    return static_cast<std::int64_t>(hash);
}
