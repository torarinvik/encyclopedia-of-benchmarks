/* Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t prolangs_c_loader_relocation_add(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 5) return -1;
    if (input[0] < 1 || input[0] > 6 || input[1] < -65535 || input[1] > 65535) return -1;
    const std::size_t width = (static_cast<std::size_t>(input[0]) + 1) / 2;
    if (length != 2 + width) return -1;
    std::uint32_t field = 0;
    for (std::size_t i = 0; i < width; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
        field = field * 256u + static_cast<std::uint32_t>(input[2 + i]);
    }
    const std::int64_t adjusted = static_cast<std::int64_t>(field) + input[1];
    if (adjusted < 0) return -1;
    if (capacity < width || output == nullptr) return -2;
    std::uint32_t result = static_cast<std::uint32_t>(adjusted);
    for (std::size_t i = width; i > 0; --i) { output[i - 1] = static_cast<std::uint8_t>(result & 255u); result >>= 8; }
    return static_cast<std::int64_t>(width);
}
