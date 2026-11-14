#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t exponential_histogram_window(const std::int64_t* input, std::size_t length,
                                                     std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 130 || input[0] < 1 || input[0] > 64 ||
        input[1] < 0 || input[1] > 128) return -1;
    auto window = static_cast<std::size_t>(input[0]), n = static_cast<std::size_t>(input[1]);
    if (length != 2+n) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2+i] != 0 && input[2+i] != 1) return -1;
    if (!output || capacity < 8*n) return -2;
    struct Bucket { std::size_t end, size; };
    std::array<Bucket, 128> buckets{};
    std::size_t used = 0;
    for (std::size_t time = 0; time < n; ++time) {
        while (used && time >= window && buckets[0].end <= time-window) {
            for (std::size_t j = 1; j < used; ++j) buckets[j-1] = buckets[j];
            --used;
        }
        if (input[2+time]) buckets[used++] = {time, 1};
        for (std::size_t size = 1; size <= 128; size *= 2) {
            std::size_t first = used, second = used, found = 0;
            for (std::size_t j = 0; j < used; ++j) if (buckets[j].size == size) {
                if (found == 0) first = j;
                else if (found == 1) second = j;
                ++found;
            }
            if (found > 2) {
                buckets[second].size = 2*size;
                for (std::size_t j = first+1; j < used; ++j) buckets[j-1] = buckets[j];
                --used;
            }
        }
        std::size_t total = 0;
        for (std::size_t j = 0; j < used; ++j) total += buckets[j].size;
        auto value = static_cast<std::uint64_t>(2*total-(used ? buckets[0].size : 0));
        for (std::size_t j = 0; j < 8; ++j) { output[8*time+j] = static_cast<std::uint8_t>(value); value >>= 8; }
    }
    return static_cast<std::int64_t>(8*n);
}
