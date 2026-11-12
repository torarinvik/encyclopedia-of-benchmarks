#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 24;
constexpr std::size_t MAX_REPETITIONS = N * N / 4;
constexpr std::size_t INPUT_MAX = N + 1;
constexpr std::size_t Z_MAX = 2 * N + 1;

void z_values(const std::array<std::int64_t, Z_MAX>& text, std::size_t length,
              std::array<std::size_t, Z_MAX>& z) {
    z.fill(0);
    std::size_t left = 0, right = 0;
    bool has_box = false;
    for (std::size_t i = 1; i < length; ++i) {
        if (has_box && i <= right) {
            const auto remaining = right - i + 1;
            z[i] = z[i - left] < remaining ? z[i - left] : remaining;
        }
        while (i + z[i] < length && text[z[i]] == text[i + z[i]]) ++z[i];
        if (!has_box || i + z[i] - 1 > right) {
            left = i;
            right = i + z[i] - 1;
            has_box = true;
        }
    }
}

std::size_t z_at(const std::array<std::size_t, Z_MAX>& z,
                 std::size_t length, std::size_t index) {
    return index < length ? z[index] : 0;
}

void divide(const std::array<std::int64_t, N>& symbols, std::size_t offset,
            std::size_t length, bool (&marked)[N][N + 1]) {
    if (length <= 1) return;
    const auto left_size = length / 2;
    const auto right_size = length - left_size;
    const auto middle = offset + left_size;
    std::array<std::int64_t, Z_MAX> buffer{};
    std::array<std::size_t, Z_MAX> z{};
    std::array<std::size_t, N> before{}, after{};

    divide(symbols, offset, left_size, marked);
    divide(symbols, middle, right_size, marked);

    for (std::size_t i = 0; i < left_size; ++i) buffer[i] = symbols[middle - 1 - i];
    z_values(buffer, left_size, z);
    for (std::size_t center = 0; center < left_size; ++center)
        before[center] = z_at(z, left_size, left_size - center);

    std::size_t used = 0;
    for (std::size_t i = 0; i < right_size; ++i) buffer[used++] = symbols[middle + i];
    buffer[used++] = -1;
    for (std::size_t i = 0; i < left_size; ++i) buffer[used++] = symbols[offset + i];
    z_values(buffer, used, z);
    for (std::size_t center = 0; center < left_size; ++center)
        after[center] = z_at(z, used, right_size + 1 + center);

    for (std::size_t i = 0; i < left_size; ++i) buffer[i] = symbols[middle - 1 - i];
    used = left_size;
    buffer[used++] = -1;
    for (std::size_t i = 0; i < right_size; ++i) buffer[used++] = symbols[offset + length - 1 - i];
    z_values(buffer, used, z);
    for (std::size_t d = 0; d < right_size; ++d)
        before[left_size + d] = z_at(z, used, left_size + 1 + right_size - 1 - d);

    for (std::size_t i = 0; i < right_size; ++i) buffer[i] = symbols[middle + i];
    z_values(buffer, right_size, z);
    for (std::size_t d = 0; d < right_size; ++d)
        after[left_size + d] = z_at(z, right_size, d + 1);

    for (std::size_t center = 0; center < length; ++center) {
        const bool left_biased = center < left_size;
        const auto half = left_biased ? left_size - center : center - left_size + 1;
        if (before[center] + after[center] < half) continue;
        const auto low = std::max<std::size_t>(1, half > after[center] ? half - after[center] : 0);
        const auto high = std::min(half, before[center]);
        for (std::size_t first_half = low; first_half <= high; ++first_half) {
            if (left_biased && first_half == half) continue;
            const auto start = left_biased
                ? center - first_half
                : center - half - first_half + 1;
            marked[offset + start][half] = true;
        }
    }
}

void store(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i)
        output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t main_lorentz_tandem_repetitions(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > INPUT_MAX) return -1;
    const auto nr = input[0];
    if (nr < 0 || nr > static_cast<std::int64_t>(N) || length != static_cast<std::size_t>(nr) + 1) return -1;
    const auto n = static_cast<std::size_t>(nr);
    std::array<std::int64_t, N> symbols{};
    for (std::size_t i = 0; i < n; ++i) {
        symbols[i] = input[i + 1];
        if (symbols[i] < 0 || symbols[i] > 255) return -1;
    }

    bool marked[N][N + 1]{};
    divide(symbols, 0, n, marked);
    std::array<std::int64_t, MAX_REPETITIONS> codes{};
    std::size_t count = 0;
    for (std::size_t start = 0; start < n; ++start)
        for (std::size_t half = 1; half <= n / 2; ++half)
            if (start + 2 * half <= n && marked[start][half])
                codes[count++] = static_cast<std::int64_t>(start * 32 + half);
    const auto required = 8 * (count + 1);
    if (output == nullptr || capacity < required) return -2;
    store(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i) store(output, 8 * (i + 1), codes[i]);
    return static_cast<std::int64_t>(required);
}
