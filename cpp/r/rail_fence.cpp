#include <cstddef>
#include <cstdint>

static std::size_t rail_for_position(std::size_t position, std::size_t rails) {
    const std::size_t period = 2 * (rails - 1);
    const std::size_t phase = position % period;
    return phase < rails ? phase : period - phase;
}

extern "C" std::int64_t rail_fence(const std::int64_t* input, std::size_t length,
                                   std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 260) return -1;
    if (input[0] < 0 || input[0] > 1 || input[1] < 2 || input[1] > 8) return -1;
    if (input[2] < 0 || input[2] > 256) return -1;
    const std::size_t mode = static_cast<std::size_t>(input[0]);
    const std::size_t rails = static_cast<std::size_t>(input[1]);
    const std::size_t n = static_cast<std::size_t>(input[2]);
    if (length != n + 3) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 3] < 0 || input[i + 3] > 127) return -1;
    }
    if (output == nullptr || capacity < n) return -2;

    if (mode == 0) {
        std::size_t out = 0;
        for (std::size_t rail = 0; rail < rails; ++rail) {
            for (std::size_t position = 0; position < n; ++position) {
                if (rail_for_position(position, rails) == rail) {
                    output[out++] = static_cast<std::uint8_t>(input[position + 3]);
                }
            }
        }
    } else {
        std::size_t counts[8] = {};
        std::size_t starts[8] = {};
        std::size_t used[8] = {};
        for (std::size_t position = 0; position < n; ++position) ++counts[rail_for_position(position, rails)];
        for (std::size_t rail = 1; rail < rails; ++rail) starts[rail] = starts[rail - 1] + counts[rail - 1];
        for (std::size_t position = 0; position < n; ++position) {
            const std::size_t rail = rail_for_position(position, rails);
            output[position] = static_cast<std::uint8_t>(input[3 + starts[rail] + used[rail]]);
            ++used[rail];
        }
    }
    return static_cast<std::int64_t>(n);
}
