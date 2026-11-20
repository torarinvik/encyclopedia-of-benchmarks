// Uncompiled monotone-cursor Prüfer decoder draft.
#include <array>
#include <cstddef>
#include <cstdint>
static void pdl_write(std::uint8_t* output, std::size_t offset, std::uint64_t value) {
    for (std::size_t i = 0; i < 8; ++i) output[offset+i] = static_cast<std::uint8_t>(value >> (8*i));
}
extern "C" std::int64_t prufer_decode_linear(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 1 || length > 4096) return -1;
    const auto nv = input[0];
    if (nv < 2 || nv > 4096 || length != static_cast<std::size_t>(nv)-1) return -1;
    const auto n = static_cast<std::size_t>(nv);
    std::array<int,4096> count{};
    for (std::size_t i = 1; i < length; ++i) {
        if (input[i] < 0 || input[i] >= nv) return -1;
        ++count[static_cast<std::size_t>(input[i])];
    }
    const auto needed = 16*(n-1);
    if (!output || capacity < needed) return -2;
    int cursor = static_cast<int>(n)-1;
    while (count[cursor] != 0) --cursor;
    int leaf = cursor;
    for (std::size_t i = 1; i < length; ++i) {
        const int v = static_cast<int>(input[i]);
        pdl_write(output, 16*(i-1), leaf); pdl_write(output, 16*(i-1)+8, v);
        count[leaf] = -1; --count[v];
        if (count[v] == 0 && v > cursor) leaf = v;
        else { do { --cursor; } while (count[cursor] != 0); leaf = cursor; }
    }
    int other = 0;
    while (other == leaf || count[other] != 0) ++other;
    pdl_write(output, 16*(n-2), leaf); pdl_write(output, 16*(n-2)+8, other);
    return static_cast<std::int64_t>(needed);
}
