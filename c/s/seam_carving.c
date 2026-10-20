/* Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
   Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_WIDTH 6
#define MAX_HEIGHT 6
#define MAX_INPUT_LENGTH 39
#define MAX_OUTPUT_BYTES 30

int64_t seam_carving(const int64_t *input, size_t length,
                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t width_value = input[0], height_value = input[1];
    if (width_value < 2 || width_value > MAX_WIDTH
            || height_value < 1 || height_value > MAX_HEIGHT) return -1;
    const size_t width = (size_t)width_value, height = (size_t)height_value;
    if (length != 2 + width * height) return -1;
    for (size_t i = 0; i < width * height; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;

    double energy[MAX_HEIGHT][MAX_WIDTH] = {{0.0}};
    double cumulative[MAX_HEIGHT][MAX_WIDTH] = {{0.0}};
    int previous_x[MAX_HEIGHT][MAX_WIDTH] = {{0}};
    size_t seam_x[MAX_HEIGHT] = {0};
    for (size_t y = 0; y < height; ++y) {
        const size_t row = y * width;
        for (size_t x = 0; x < width; ++x) {
            const double middle = (double)input[2 + row + x];
            double left_energy = 0.0, right_energy = 0.0;
            if (x > 0) {
                const double difference = (double)input[2 + row + x - 1] - middle;
                left_energy = difference * difference + difference * difference
                    + difference * difference;
            }
            if (x + 1 < width) {
                const double difference = (double)input[2 + row + x + 1] - middle;
                right_energy = difference * difference + difference * difference
                    + difference * difference;
            }
            energy[y][x] = sqrt(left_energy + right_energy);
        }
    }
    for (size_t x = 0; x < width; ++x) cumulative[0][x] = energy[0][x];
    for (size_t y = 1; y < height; ++y) {
        for (size_t x = 0; x < width; ++x) {
            double minimum = INFINITY;
            size_t best_x = x;
            const size_t start = x == 0 ? 0 : x - 1;
            const size_t end = x + 1 < width ? x + 1 : width - 1;
            for (size_t candidate = start; candidate <= end; ++candidate) {
                if (cumulative[y - 1][candidate] < minimum) {
                    minimum = cumulative[y - 1][candidate];
                    best_x = candidate;
                }
            }
            cumulative[y][x] = minimum + energy[y][x];
            previous_x[y][x] = (int)best_x;
        }
    }
    size_t last_x = 0;
    double minimum = cumulative[height - 1][0];
    for (size_t x = 1; x < width; ++x) {
        if (cumulative[height - 1][x] < minimum) {
            minimum = cumulative[height - 1][x];
            last_x = x;
        }
    }
    seam_x[height - 1] = last_x;
    for (size_t y = height - 1; y > 0; --y)
        seam_x[y - 1] = (size_t)previous_x[y][seam_x[y]];

    const size_t needed = height * (width - 1);
    if (output == NULL || output_capacity < needed) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t position = 0;
    for (size_t y = 0; y < height; ++y) {
        const size_t row = y * width;
        for (size_t x = 0; x < width; ++x) {
            if (x != seam_x[y]) staged[position++] = (uint8_t)input[2 + row + x];
        }
    }
    for (size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return (int64_t)needed;
}
