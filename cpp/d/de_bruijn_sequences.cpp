#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_order = 16;
constexpr std::size_t max_cycle_length = 10000;

void fkm_generate(std::size_t position, std::size_t period, std::size_t order,
                  std::size_t alphabet, std::uint8_t* work,
                  std::uint8_t* output, std::size_t* emitted) noexcept {
    if (position > order) {
        if (order % period == 0) {
            for (std::size_t index = 1; index <= period; ++index)
                output[(*emitted)++] = static_cast<std::uint8_t>('0' + work[index]);
        }
        return;
    }
    work[position] = work[position - period];
    fkm_generate(position + 1, period, order, alphabet, work, output, emitted);
    for (std::size_t symbol = static_cast<std::size_t>(work[position - period]) + 1;
         symbol < alphabet; ++symbol) {
        work[position] = static_cast<std::uint8_t>(symbol);
        fkm_generate(position + 1, position, order, alphabet, work, output, emitted);
    }
}
}

extern "C" std::int64_t de_bruijn_sequences(const std::int64_t* input,
                                             std::size_t length,
                                             std::uint8_t* output,
                                             std::size_t capacity) noexcept {
    if (input == nullptr || length != 2) return -1;
    if (input[0] < 2 || input[0] > 10 || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_order)) return -1;
    const auto alphabet = static_cast<std::size_t>(input[0]);
    const auto order = static_cast<std::size_t>(input[1]);
    std::size_t cycle_length = 1;
    for (std::size_t step = 0; step < order; ++step) {
        if (cycle_length > max_cycle_length / alphabet) return -1;
        cycle_length *= alphabet;
    }
    const std::size_t output_length = cycle_length + order - 1;
    if (capacity < output_length || output == nullptr) return -2;
    std::uint8_t work[max_order + 1]{};
    std::size_t emitted = 0;
    fkm_generate(1, 1, order, alphabet, work, output, &emitted);
    for (std::size_t index = 0; index + 1 < order; ++index)
        output[cycle_length + index] = output[index];
    return static_cast<std::int64_t>(output_length);
}
