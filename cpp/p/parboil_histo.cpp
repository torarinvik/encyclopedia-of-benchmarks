#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_BINS = 256, MAX_SAMPLES = 1024, MAX_INPUT = 3 + MAX_SAMPLES;
}

extern "C" std::int64_t parboil_histo(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) {
    std::uint8_t histogram[MAX_BINS]{};
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const std::int64_t iterations = input[0], bins = input[1], samples = input[2];
    if (iterations < 0 || iterations > 8 || bins < 1 || bins > static_cast<std::int64_t>(MAX_BINS) ||
        samples < 0 || samples > static_cast<std::int64_t>(MAX_SAMPLES) ||
        length != static_cast<std::size_t>(3 + samples)) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(samples); ++i)
        if (input[3 + i] < 0 || input[3 + i] >= bins) return -1;
    if (output == nullptr || capacity < static_cast<std::size_t>(bins)) return -2;
    for (std::int64_t iter = 0; iter < iterations; ++iter) {
        for (std::size_t i = 0; i < static_cast<std::size_t>(bins); ++i) histogram[i] = 0;
        for (std::size_t i = 0; i < static_cast<std::size_t>(samples); ++i) {
            auto &count = histogram[static_cast<std::size_t>(input[3 + i])];
            if (count < 255u) ++count;
        }
    }
    for (std::size_t i = 0; i < static_cast<std::size_t>(bins); ++i) output[i] = histogram[i];
    return bins;
}
