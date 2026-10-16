#include <cstddef>
#include <cstdint>
#include <cstring>
namespace {
std::size_t get16(const std::uint8_t* p, std::size_t i) { return p[i] | (std::size_t(p[i + 1]) << 8); }
void put16(std::uint8_t* p, std::size_t i, std::size_t x) { p[i] = std::uint8_t(x); p[i + 1] = std::uint8_t(x >> 8); }
bool op(std::int64_t x) { return x == '+' || x == '-' || x == '*' || x == '/' || x == '^'; }
bool letter(std::int64_t x) { return (x >= 'A' && x <= 'Z') || (x >= 'a' && x <= 'z'); }
}
extern "C" std::int64_t postfix_to_infix(const std::int64_t* v, std::size_t n, std::uint8_t* out, std::size_t cap) noexcept {
    if (!v || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != std::size_t(v[0]) + 1) return -1;
    if (!out || cap < 8192) return -2;
    const auto count = std::size_t(v[0]); if (!count) return 0;
    if (count == 1) { if (!letter(v[1])) return -1; out[0] = std::uint8_t(v[1]); return 1; }
    std::size_t stack = 0, scratch = 256;
    for (std::size_t i = 0; i < count; ++i) {
        const auto x = v[i + 1];
        if (op(x)) {
            if (stack < 2) return -1;
            const auto l = stack - 2, r = stack - 1;
            const auto ls = get16(out, l * 4), ll = get16(out, l * 4 + 2), rs = get16(out, r * 4), rl = get16(out, r * 4 + 2);
            const auto start = scratch; out[scratch++] = '('; std::memcpy(out + scratch, out + ls, ll); scratch += ll;
            out[scratch++] = std::uint8_t(x); std::memcpy(out + scratch, out + rs, rl); scratch += rl; out[scratch++] = ')';
            put16(out, l * 4, start); put16(out, l * 4 + 2, scratch - start); --stack;
        } else {
            if (!letter(x)) return -1;
            put16(out, stack * 4, scratch); put16(out, stack * 4 + 2, 1); out[scratch++] = std::uint8_t(x); ++stack;
        }
        if (scratch > cap) return -2;
    }
    if (stack != 1) return -1;
    const auto start = get16(out, 0), len = get16(out, 2); std::memmove(out, out + start, len); return std::int64_t(len);
}
