#include <stddef.h>
#include <stdint.h>
#include <math.h>

/* Parboil TPACF, Illinois Open Source License; see package LICENSE.txt. */
enum { MAX_POINTS = 4, NUM_BINS = 20, MAX_INPUT_LENGTH = 26 };
static const double PI_VALUE = 3.141592653589793238462643383279502884;

static float coordinate(const int64_t *input, size_t offset)
{
    return (float)input[offset] / 1000000.0f;
}

int64_t parboil_tpacf_cross_correlation(const int64_t *input,
        size_t input_length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 8u || input_length > MAX_INPUT_LENGTH) return -1;
    const int64_t data_value = input[0], random_value = input[1];
    if (data_value < 1 || data_value > MAX_POINTS || random_value < 1 || random_value > MAX_POINTS) return -1;
    const size_t data_count = (size_t)data_value, random_count = (size_t)random_value;
    if (input_length != 2u + 3u * (data_count + random_count)) return -1;
    for (size_t i = 2; i < input_length; ++i)
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (output == NULL || output_capacity < NUM_BINS) return -2;

    float boundaries[NUM_BINS + 1];
    for (int k = 0; k <= NUM_BINS; ++k) {
        const double exponent = log10(1.0) + (double)k * 1.0 / 5.0;
        const double arcminutes = pow(10.0, exponent);
        const double radians = arcminutes / 60.0 * (PI_VALUE / 180.0);
        boundaries[k] = (float)cos(radians);
    }
    uint8_t histogram[NUM_BINS] = {0};
    const size_t random_base = 2u + 3u * data_count;
    for (size_t j = 0; j < random_count; ++j) {
        const float rx = coordinate(input, random_base + 3u * j);
        const float ry = coordinate(input, random_base + 3u * j + 1u);
        const float rz = coordinate(input, random_base + 3u * j + 2u);
        for (size_t i = 0; i < data_count; ++i) {
            const float dx = coordinate(input, 2u + 3u * i);
            const float dy = coordinate(input, 2u + 3u * i + 1u);
            const float dz = coordinate(input, 2u + 3u * i + 2u);
            const float px = dx * rx;
            const float py = dy * ry;
            const float pz = dz * rz;
            const float xy = px + py;
            const float distance = xy + pz;
            int min = 0, max = NUM_BINS;
            while (max > min + 1) {
                const int middle = (min + max) / 2;
                if (distance >= boundaries[middle]) max = middle;
                else min = middle;
            }
            if (distance < boundaries[min] && distance >= boundaries[max])
                ++histogram[max - 1];
        }
    }
    for (size_t bin = 0; bin < NUM_BINS; ++bin) output[bin] = histogram[bin];
    return NUM_BINS;
}
