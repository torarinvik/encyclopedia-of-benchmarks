/* Emit the nearest strictly smaller value to the left of every input value. */
#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) output[offset+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
}
extern "C" std::int64_t next_smaller_element(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 1 || input[0] < 0 || input[0] > 1024 || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    for (std::size_t i=0;i<n;++i) if (input[i+1] < INT32_MIN || input[i+1] > INT32_MAX) return -1;
    if (capacity < n*8 || (n > 0 && !output)) return -2;
    std::int64_t stack[1024]; std::size_t top=0;
    for (std::size_t i=0;i<n;++i) {
        const auto value=input[i+1];
        while (top>0 && stack[top-1]>=value) --top;
        put_i64_le(output,i*8,top>0?stack[top-1]:-1);
        stack[top++]=value;
    }
    return static_cast<std::int64_t>(n*8);
}
