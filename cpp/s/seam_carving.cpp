// Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
// Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t seam_carving(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 39) return -1;
    const std::int64_t width_value = input[0], height_value = input[1];
    if (width_value < 2 || width_value > 6 || height_value < 1 || height_value > 6) return -1;
    const std::size_t width = static_cast<std::size_t>(width_value);
    const std::size_t height = static_cast<std::size_t>(height_value);
    if (length != 2 + width * height) return -1;
    for (std::size_t i = 0; i < width * height; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;

    double energy[6][6] = {}, cumulative[6][6] = {};
    int previous_x[6][6] = {};
    std::size_t seam_x[6] = {};
    for (std::size_t y = 0; y < height; ++y) {
        const std::size_t row = y * width;
        for (std::size_t x = 0; x < width; ++x) {
            const double middle = static_cast<double>(input[2 + row + x]);
            double left_energy = 0.0, right_energy = 0.0;
            if (x > 0) {
                const double difference = static_cast<double>(input[2 + row + x - 1]) - middle;
                left_energy = difference * difference + difference * difference + difference * difference;
            }
            if (x + 1 < width) {
                const double difference = static_cast<double>(input[2 + row + x + 1]) - middle;
                right_energy = difference * difference + difference * difference + difference * difference;
            }
            energy[y][x] = std::sqrt(left_energy + right_energy);
        }
    }
    for (std::size_t x = 0; x < width; ++x) cumulative[0][x] = energy[0][x];
    for (std::size_t y = 1; y < height; ++y) {
        for (std::size_t x = 0; x < width; ++x) {
            double minimum = std::numeric_limits<double>::infinity();
            std::size_t best_x = x;
            const std::size_t start = x == 0 ? 0 : x - 1;
            const std::size_t end = x + 1 < width ? x + 1 : width - 1;
            for (std::size_t candidate = start; candidate <= end; ++candidate) {
                if (cumulative[y - 1][candidate] < minimum) {
                    minimum = cumulative[y - 1][candidate];
                    best_x = candidate;
                }
            }
            cumulative[y][x] = minimum + energy[y][x];
            previous_x[y][x] = static_cast<int>(best_x);
        }
    }
    std::size_t last_x = 0;
    double minimum = cumulative[height - 1][0];
    for (std::size_t x = 1; x < width; ++x) {
        if (cumulative[height - 1][x] < minimum) {
            minimum = cumulative[height - 1][x];
            last_x = x;
        }
    }
    seam_x[height - 1] = last_x;
    for (std::size_t y = height - 1; y > 0; --y)
        seam_x[y - 1] = static_cast<std::size_t>(previous_x[y][seam_x[y]]);

    const std::size_t needed = height * (width - 1);
    if (output == nullptr || output_capacity < needed) return -2;
    std::uint8_t staged[30];
    std::size_t position = 0;
    for (std::size_t y = 0; y < height; ++y) {
        for (std::size_t x = 0; x < width; ++x) {
            if (x != seam_x[y]) staged[position++] = static_cast<std::uint8_t>(input[2 + y * width + x]);
        }
    }
    for (std::size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(needed);
}
