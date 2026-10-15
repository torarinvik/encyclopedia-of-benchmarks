#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hash_xor8(const std::int64_t *values, std::size_t length)
{
    if ((values == nullptr && length != 0) || length > 100001) return -1;
    for (std::size_t i = 0; i < length && values[i] != 0; ++i)
        if (values[i] < 0 || values[i] > 127) return -1;
    std::uint32_t hash = 0;
    for (std::size_t i = 0; i < length && values[i] != 0; ++i)
        hash = (hash + static_cast<std::uint32_t>(values[i])) & 0xffu;
    return static_cast<std::int64_t>(((hash ^ 0xffu) + 1u) & 0xffu);
}
