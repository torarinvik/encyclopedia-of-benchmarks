#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_candidates = 2048;
constexpr std::int64_t max_bound = 4096;
}

extern "C" std::int64_t lucky_number_sieve(const std::int64_t* input,
                                            std::size_t length,
                                            std::uint8_t* output,
                                            std::size_t capacity) noexcept {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t mode = input[0];
    const std::int64_t bound = input[1];
    if ((mode != 0 && mode != 1) || bound < 0 || bound > max_bound) return -1;

    std::int64_t candidates[max_candidates]{};
    std::size_t count = 0;
    const std::int64_t first = mode == 0 ? 1 : 2;
    for (std::int64_t value = first; value <= bound; value += 2)
        candidates[count++] = value;

    std::size_t selected = 1;
    while (selected < count) {
        const auto step = static_cast<std::size_t>(candidates[selected]);
        if (step > count) break;
        std::size_t write = 0;
        std::size_t rank = 0;
        for (std::size_t read = 0; read < count; ++read) {
            ++rank;
            if (rank % step != 0) candidates[write++] = candidates[read];
        }
        count = write;
        ++selected;
    }

    const std::size_t output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto bits = static_cast<std::uint64_t>(candidates[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
