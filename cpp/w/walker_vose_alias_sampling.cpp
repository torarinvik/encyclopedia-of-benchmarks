#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

extern "C" int64_t walker_vose_alias_sampling(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 83) return -1;
    const int64_t nr = input[0], qr = input[1];
    if (nr < 1 || nr > 16 || qr < 0 || qr > 32) return -1;
    const size_t n = static_cast<size_t>(nr), q = static_cast<size_t>(qr);
    if (length != 2 + n + 2 * q) return -1;
    int64_t total = 0;
    for (size_t i = 0; i < n; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 100) return -1;
        total += input[2 + i];
    }
    if (!total) return -1;
    for (size_t i = 0; i < q; ++i) {
        const auto col = input[2 + n + 2 * i], ticket = input[3 + n + 2 * i];
        if (col < 0 || col >= nr || ticket < 0 || ticket >= total) return -1;
    }
    if (!q) return 0;
    if (!output || capacity < 8 * q) return -2;
    std::array<int64_t, 16> mass{}, threshold{};
    std::array<size_t, 16> alias{};
    std::vector<size_t> small, large;
    small.reserve(n); large.reserve(n);
    for (size_t i = 0; i < n; ++i) {
        mass[i] = nr * input[2 + i]; threshold[i] = total; alias[i] = i;
        (mass[i] < total ? small : large).push_back(i);
    }
    while (!small.empty() && !large.empty()) {
        size_t low = small.back(); small.pop_back();
        size_t high = large.back(); large.pop_back();
        threshold[low] = mass[low]; alias[low] = high;
        mass[high] -= total - mass[low];
        (mass[high] < total ? small : large).push_back(high);
    }
    std::array<uint8_t, 256> staged{};
    for (size_t i = 0; i < q; ++i) {
        size_t column = static_cast<size_t>(input[2 + n + 2 * i]);
        uint64_t value = input[3 + n + 2 * i] < threshold[column] ? column : alias[column];
        for (size_t b = 0; b < 8; ++b) staged[8 * i + b] = static_cast<uint8_t>(value >> (8 * b));
    }
    for (size_t i = 0; i < 8 * q; ++i) output[i] = staged[i];
    return static_cast<int64_t>(8 * q);
}
