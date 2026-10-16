#include <cstddef>
#include <cstdint>

extern "C" std::int64_t optimal_file_merging(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || length > 33) return -1;
    const auto count = values[0];
    if (count < 0 || count > 32 || length != static_cast<std::size_t>(count) + 1) return -1;
    std::int64_t files[32]{};
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        if (values[i + 1] < 0 || values[i + 1] > 1000000) return -1;
        files[i] = values[i + 1];
    }
    auto n = static_cast<std::size_t>(count);
    std::int64_t total = 0;
    while (n > 1) {
        std::size_t a = 0, b = 1;
        if (files[b] < files[a]) { auto t = a; a = b; b = t; }
        for (std::size_t i = 2; i < n; ++i) {
            if (files[i] < files[a]) { b = a; a = i; }
            else if (files[i] < files[b]) b = i;
        }
        const auto merged = files[a] + files[b]; total += merged;
        if (a > b) { auto t = a; a = b; b = t; }
        files[a] = merged; files[b] = files[n - 1]; --n;
    }
    return total;
}
