#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t begin = 2001, end = 2002; struct Parser { const std::int64_t* a; std::size_t n, i; bool ok; };
std::int64_t parse(Parser& p, int depth, bool nested) {
    if (depth > 16) { p.ok = false; return 0; }
    std::int64_t sum = 0;
    while (p.i < p.n) { auto x = p.a[p.i++]; if (x == end) { if (!nested) p.ok = false; return sum * depth; }
        if (x == begin) sum += parse(p, depth + 1, true);
        else if (x >= -1000 && x <= 1000) sum += x; else { p.ok = false; return 0; }
        if (!p.ok) return 0;
    }
    if (nested) p.ok = false; return sum * depth;
} }
extern "C" std::int64_t product_sum(const std::int64_t* v, std::size_t n) noexcept {
    if (!v || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != static_cast<std::size_t>(v[0]) + 1) return -1;
    Parser p{v + 1, static_cast<std::size_t>(v[0]), 0, true}; auto result = parse(p, 1, false);
    return p.ok && p.i == p.n ? result : -1;
}
