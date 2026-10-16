// Bounded operation stream for the source MinHeap API.
#include <cstddef>
#include <cstdint>
#include <climits>

static void put_i64(std::uint8_t *out, std::size_t slot, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[slot * 8 + b] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
static void sift_down(std::int64_t *h, std::size_t n, std::size_t i) {
    for (;;) { auto l = 2 * i + 1, r = l + 1, s = i; if (l < n && h[l] < h[s]) s = l; if (r < n && h[r] < h[s]) s = r; if (s == i) return; auto t = h[i]; h[i] = h[s]; h[s] = t; i = s; }
}
static void bubble_up(std::int64_t *h, std::size_t i) {
    while (i) { auto p = (i - 1) / 2; if (h[p] <= h[i]) break; auto t = h[i]; h[i] = h[p]; h[p] = t; i = p; }
}
extern "C" std::int64_t binary_heap_indexed_operations(const std::int64_t *v, std::size_t n, std::uint8_t *out, std::size_t cap) noexcept {
    if (!v || n < 2 || v[0] < 1 || v[0] > 256 || v[1] < 0 || v[1] > 512 || n != 2 + static_cast<std::size_t>(v[1]) * 3) return -1;
    std::int64_t h[256]; std::size_t size = 0, outputs = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(v[1]); ++i) {
        auto op = v[2 + 3*i], a = v[3 + 3*i], b = v[4 + 3*i];
        if (op == 0) { if (a < INT32_MIN || a > INT32_MAX || b != 0) return -1; if (size < static_cast<std::size_t>(v[0])) { h[size] = a; bubble_up(h, size++); } }
        else if (op == 1 || op == 2) { if (a || b || (op == 1 && !size)) return -1; if (!out || (outputs + 1) * 8 > cap) return -2; auto result = size ? h[0] : INT32_MAX; if (op == 2 && size) { h[0] = h[--size]; if (size) sift_down(h,size,0); } put_i64(out,outputs++,result); }
        else if (op == 3) { if (a < 0 || static_cast<std::uint64_t>(a) >= size || b < INT32_MIN || b > INT32_MAX || b > h[a]) return -1; h[a] = b; bubble_up(h,static_cast<std::size_t>(a)); }
        else if (op == 4) { if (a < 0 || static_cast<std::uint64_t>(a) >= size || b) return -1; h[a] = INT32_MIN; bubble_up(h,static_cast<std::size_t>(a)); h[0] = h[--size]; if (size) sift_down(h,size,0); }
        else return -1;
    }
    auto bytes = outputs * 8; if (bytes > cap || (bytes && !out)) return -2; return static_cast<std::int64_t>(bytes);
}
