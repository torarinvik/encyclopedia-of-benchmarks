#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t pattern_count = 10;
constexpr std::size_t max_neurons = 8;
constexpr std::size_t max_input_length = 94;

float activation(float value) {
    double x = value;
    if (x > 200.0) x = 200.0;
    if (x < -200.0) x = -200.0;
    const double e = std::exp(-x);
    return static_cast<float>((1.0 - e) / (1.0 + e));
}

int run_cont(const float *weights, const std::int64_t *source, std::size_t neurons, std::int64_t *dest) {
    float temp_a[max_neurons];
    std::int64_t temp_c[max_neurons];
    for (std::size_t neuron = 0; neuron < neurons; ++neuron) temp_a[neuron] = static_cast<float>(dest[neuron] = source[neuron]);
    bool stable = false, threshold = false;
    int iterations = 0;
    while (!stable && iterations < 500) {
        int threshold_iterations = 0;
        for (std::size_t row = 0; row < neurons; ++row) {
            float sum = 0.0f;
            for (std::size_t neuron = 0; neuron < neurons; ++neuron) sum += weights[row * neurons + neuron] * static_cast<float>(source[neuron]);
            temp_a[row] = activation(sum);
        }
        while (!threshold && threshold_iterations < 50) {
            threshold = true;
            for (std::size_t row = 0; row < neurons; ++row) {
                if (std::fabs(static_cast<double>(temp_a[row])) < 0.7) {
                    float sum = 0.0f;
                    for (std::size_t neuron = 0; neuron < neurons; ++neuron) sum += weights[row * neurons + neuron] * temp_a[neuron];
                    temp_a[row] = activation(sum);
                    if (temp_a[row] < 0.7f) threshold = false;
                }
            }
            ++threshold_iterations;
        }
        bool same = true;
        for (std::size_t neuron = 0; neuron < neurons; ++neuron) {
            temp_c[neuron] = temp_a[neuron] > 0.0f ? 1 : -1;
            if (dest[neuron] != temp_c[neuron]) same = false;
        }
        if (same) stable = true;
        else {
            for (std::size_t neuron = 0; neuron < neurons; ++neuron) if (dest[neuron] != temp_c[neuron]) { dest[neuron] = temp_c[neuron]; break; }
            for (std::size_t neuron = 0; neuron < neurons; ++neuron) temp_a[neuron] = static_cast<float>(dest[neuron]);
        }
        ++iterations;
    }
    return iterations == 500 ? -1 : iterations;
}
}

extern "C" std::int64_t freebench_neural_hopfield(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const auto width = input[0], height = input[1], count = input[2];
    if (width < 1 || width > 8 || height < 1 || height > 8 || count != static_cast<std::int64_t>(pattern_count)) return -1;
    const auto neurons = static_cast<std::size_t>(width * height);
    if (neurons < 2 || neurons > max_neurons || length != 3 + pattern_count * (1 + neurons)) return -1;
    std::int64_t patterns[pattern_count][max_neurons];
    std::size_t offset = 3;
    for (std::size_t pattern = 0; pattern < pattern_count; ++pattern) {
        const auto label = input[offset++];
        if (label < 65 || label > 90) return -1;
        for (std::size_t neuron = 0; neuron < neurons; ++neuron) {
            const auto cell = input[offset++];
            if (cell != -1 && cell != 1) return -1;
            patterns[pattern][neuron] = cell;
            if (pattern != 0 && cell != patterns[0][neuron]) return -1;
        }
    }
    int hamming_warnings = 0;
    for (std::size_t first = 0; first < pattern_count; ++first) for (std::size_t second = first + 1; second < pattern_count; ++second) {
        int normal = 0, complement = 0;
        for (std::size_t neuron = 0; neuron < neurons; ++neuron) {
            if (patterns[first][neuron] != patterns[second][neuron]) ++normal;
            if (patterns[first][neuron] != -patterns[second][neuron]) ++complement;
        }
        if (normal < 2) ++hamming_warnings;
        if (complement < 2) ++hamming_warnings;
    }
    (void)hamming_warnings;
    float weights[max_neurons * max_neurons]{};
    for (std::size_t pattern = 0; pattern < pattern_count; ++pattern)
        for (std::size_t row = 0; row < neurons; ++row)
            for (std::size_t column = 0; column < neurons; ++column)
                if (row == column) weights[row * neurons + column] = 0.0f;
                else weights[row * neurons + column] += static_cast<float>(patterns[pattern][row] * patterns[pattern][column]);
    bool converged = false;
    for (std::size_t pass = 0; pass < 1; ++pass) {
        bool status = true;
        for (std::size_t pattern = 0; pattern < pattern_count; ++pattern) {
            std::int64_t recalled[max_neurons];
            if (run_cont(weights, patterns[pattern], neurons, recalled) < 0) return -2;
            float correction[max_neurons];
            for (std::size_t neuron = 0; neuron < neurons; ++neuron) {
                correction[neuron] = static_cast<float>(patterns[pattern][neuron] - recalled[neuron]) * 0.5f;
                if (correction[neuron] != 0.0f) status = false;
            }
            for (std::size_t row = 0; row < neurons; ++row)
                for (std::size_t column = 0; column < neurons; ++column)
                    if (row == column) weights[row * neurons + column] = 0.0f;
                    else weights[row * neurons + column] += correction[row] * static_cast<float>(patterns[pattern][column]);
        }
        if (status) { converged = true; break; }
    }
    if (!converged) return -2;
    std::int64_t stored_count = 0;
    for (std::size_t pattern = 0; pattern < pattern_count; ++pattern) {
        std::int64_t recalled[max_neurons];
        if (run_cont(weights, patterns[pattern], neurons, recalled) < 0) return -2;
        bool stored = true;
        for (std::size_t neuron = 0; neuron < neurons; ++neuron) if (patterns[pattern][neuron] != recalled[neuron]) stored = false;
        if (stored) ++stored_count;
    }
    return stored_count;
}
