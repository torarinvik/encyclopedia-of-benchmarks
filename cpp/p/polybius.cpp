#include <cstddef>
#include <cstdint>
extern "C" std::int64_t polybius(const std::int64_t* v, std::size_t n, std::uint8_t* out, std::size_t cap) noexcept {
    if (!v || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != std::size_t(v[0]) + 1) return -1;
    const auto count = std::size_t(v[0]), needed = count * 2;
    if (needed > cap || (needed && !out)) return -2;
    std::size_t k = 0;
    for (std::size_t i = 0; i < count; ++i) { auto x = v[i + 1]; if (x >= 'a' && x <= 'z') x -= 32; if (x < 'A' || x > 'Z' || x == 'J') return -1; auto index = int(x - 'A'); if (x > 'J') --index; out[k++] = std::uint8_t('A' + index / 5); out[k++] = std::uint8_t('A' + index % 5); }
    return std::int64_t(needed);
}
