#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_BATCH = 8, MAX_TIME = 16, MAX_VOCAB = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 3 + MAX_BATCH * MAX_TIME * (MAX_VOCAB + 1);
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double perplexity_loss(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t bval = values[0], tval = values[1], vval = values[2];
    if (bval < 1 || bval > MAX_BATCH || tval < 1 || tval > MAX_TIME || vval < 2 || vval > MAX_VOCAB) return INVALID_RESULT;
    const std::size_t batch = static_cast<std::size_t>(bval), time = static_cast<std::size_t>(tval), vocab = static_cast<std::size_t>(vval);
    const std::size_t tokens = batch * time, probability_base = 3 + tokens;
    if (length != probability_base + tokens * vocab) return INVALID_RESULT;
    for (std::size_t row = 0; row < tokens; ++row) {
        const std::int64_t label = values[3 + row];
        if (label < 0 || static_cast<std::size_t>(label) >= vocab) return INVALID_RESULT;
        std::int64_t row_sum = 0;
        for (std::size_t c = 0; c < vocab; ++c) {
            const std::int64_t p = values[probability_base + row * vocab + c];
            if (p < 0 || p > 1000000) return INVALID_RESULT;
            row_sum += p;
        }
        if (row_sum != 1000000) return INVALID_RESULT;
    }
    double batch_total = 0.0;
    for (std::size_t sentence = 0; sentence < batch; ++sentence) {
        double log_total = 0.0;
        for (std::size_t step = 0; step < time; ++step) {
            const std::size_t row = sentence * time + step;
            const std::size_t label = static_cast<std::size_t>(values[3 + row]);
            double p = static_cast<double>(values[probability_base + row * vocab + label]) / 1000000.0;
            if (p < 1e-7) p = 1e-7;
            if (p > 1.0) p = 1.0;
            log_total += std::log(p);
        }
        batch_total += std::exp(-(log_total / static_cast<double>(time)));
    }
    return batch_total / static_cast<double>(batch);
}
