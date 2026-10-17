#include <cstddef>
#include <cstdint>
#include <climits>
namespace {
void store_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t b = 0; b < 4; ++b) output[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}
extern "C" std::int64_t hungarian_algorithm(const std::int32_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 67) return -1;
    const auto rows = input[0], cols = input[1];
    if (rows < 1 || rows > 8 || cols < 1 || cols > 8 || length != 2u + static_cast<std::size_t>(rows * cols)) return -1;
    for (std::size_t k = 0; k < static_cast<std::size_t>(rows * cols); ++k) if (input[2 + k] < 0 || input[2 + k] > 1000) return -1;
    const int n = rows > cols ? rows : cols;
    std::int32_t a[81]{}, u[9]{}, v[9]{}, p[9]{}, way[9]{};
    for (int i = 0; i < rows; ++i) for (int j = 0; j < cols; ++j) a[i * 9 + j] = input[2 + i * cols + j];
    for (int i = 1; i <= n; ++i) {
        p[0] = i; int j0 = 0; std::int32_t minv[9]; bool used[9]{};
        for (int j = 0; j <= n; ++j) minv[j] = INT32_MAX;
        do {
            used[j0] = true; const int i0 = p[j0]; std::int32_t delta = INT32_MAX; int j1 = 0;
            for (int j = 1; j <= n; ++j) if (!used[j]) {
                const auto cur = a[(i0 - 1) * 9 + j - 1] - u[i0] - v[j];
                if (cur < minv[j]) { minv[j] = cur; way[j] = j0; }
                if (minv[j] < delta) { delta = minv[j]; j1 = j; }
            }
            for (int j = 0; j <= n; ++j) { if (used[j]) { u[p[j]] += delta; v[j] -= delta; } else minv[j] -= delta; }
            j0 = j1;
        } while (p[j0] != 0);
        do { const int j1 = way[j0]; p[j0] = p[j1]; j0 = j1; } while (j0 != 0);
    }
    int match[9]; for (int i = 0; i < 9; ++i) match[i] = -1;
    for (int j = 1; j <= n; ++j) if (p[j] != 0) match[p[j] - 1] = j - 1;
    std::int32_t assignments[8], total = 0;
    for (int i = 0; i < rows; ++i) { const int j = match[i]; assignments[i] = j >= 0 && j < cols ? j : -1; if (assignments[i] >= 0) total += input[2 + i * cols + assignments[i]]; }
    const auto bytes = 4u * (static_cast<std::size_t>(rows) + 1u);
    if (output == nullptr || capacity < bytes) return -2;
    for (int i = 0; i < rows; ++i) store_i32_le(output, 4u * static_cast<std::size_t>(i), assignments[i]);
    store_i32_le(output, 4u * static_cast<std::size_t>(rows), total);
    return static_cast<std::int64_t>(bytes);
}
