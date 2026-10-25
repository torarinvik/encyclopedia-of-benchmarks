#include <cmath>
#include <cstddef>
#include <cstdint>

/* Parboil TPACF, Illinois Open Source License; see package LICENSE.txt. */
namespace {
constexpr std::size_t MAX_POINTS = 4;
constexpr int NUM_BINS = 20;
constexpr std::size_t MAX_INPUT_LENGTH = 26;
constexpr double PI_VALUE = 3.141592653589793238462643383279502884;

float coordinate(const std::int64_t *input, std::size_t offset)
{
    return static_cast<float>(input[offset]) / 1000000.0f;
}
}

extern "C" std::int64_t parboil_tpacf_cross_correlation(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 8 || input_length > MAX_INPUT_LENGTH) return -1;
    const auto data_value = input[0], random_value = input[1];
    if (data_value < 1 || data_value > MAX_POINTS || random_value < 1 || random_value > MAX_POINTS) return -1;
    const auto data_count = static_cast<std::size_t>(data_value);
    const auto random_count = static_cast<std::size_t>(random_value);
    if (input_length != 2 + 3 * (data_count + random_count)) return -1;
    for (std::size_t i = 2; i < input_length; ++i)
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == nullptr || output_capacity < NUM_BINS) return -2;

    float boundaries[NUM_BINS + 1];
    for (int k = 0; k <= NUM_BINS; ++k) {
        const double exponent = std::log10(1.0) + static_cast<double>(k) * 1.0 / 5.0;
        const double arcminutes = std::pow(10.0, exponent);
        const double radians = arcminutes / 60.0 * (PI_VALUE / 180.0);
        boundaries[k] = static_cast<float>(std::cos(radians));
    }
    std::uint8_t histogram[NUM_BINS] = {};
    const std::size_t random_base = 2 + 3 * data_count;
    for (std::size_t j = 0; j < random_count; ++j) {
        const float rx = coordinate(input, random_base + 3 * j);
        const float ry = coordinate(input, random_base + 3 * j + 1);
        const float rz = coordinate(input, random_base + 3 * j + 2);
        for (std::size_t i = 0; i < data_count; ++i) {
            const float dx = coordinate(input, 2 + 3 * i);
            const float dy = coordinate(input, 2 + 3 * i + 1);
            const float dz = coordinate(input, 2 + 3 * i + 2);
            const float px = dx * rx, py = dy * ry, pz = dz * rz;
            const float xy = px + py;
            const float distance = xy + pz;
            int min = 0, max = NUM_BINS;
            while (max > min + 1) {
                const int middle = (min + max) / 2;
                if (distance >= boundaries[middle]) max = middle;
                else min = middle;
            }
            if (distance < boundaries[min] && distance >= boundaries[max]) ++histogram[max - 1];
        }
    }
    for (int bin = 0; bin < NUM_BINS; ++bin) output[bin] = histogram[bin];
    return NUM_BINS;
}
