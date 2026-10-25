/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int min_side = 15;
constexpr int max_side = 16;
constexpr int max_parseable_input_length = 258;
constexpr int mask_radius = 7;

int reflect_index(int index, int side) {
    if (index < 0) return -index - 1;
    if (index >= side) return 2 * side - index - 1;
    return index;
}

void setup_weights(std::array<int, 511>& brightness, std::array<int, 225>& distance) {
    for (int difference = -255; difference <= 255; ++difference) {
        float temp = static_cast<float>(difference) / 20.0f;
        temp = temp * temp;
        temp = static_cast<float>(100.0 * std::exp(-static_cast<double>(temp)));
        brightness[static_cast<std::size_t>(difference + 255)] = static_cast<int>(temp);
    }
    std::size_t index = 0;
    for (int dy = -mask_radius; dy <= mask_radius; ++dy) {
        for (int dx = -mask_radius; dx <= mask_radius; ++dx) {
            const float temp = -16.0f;
            const int squared_distance = dx * dx + dy * dy;
            distance[index++] = static_cast<int>(100.0 * std::exp(
                static_cast<double>(static_cast<float>(squared_distance) / temp)));
        }
    }
}

std::uint8_t median_eight(const std::array<std::uint8_t, 256>& image, int side, int y, int x) {
    std::array<int, 8> values{};
    int count = 0;
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            if (dx == 0 && dy == 0) continue;
            const int sy = reflect_index(y + dy, side);
            const int sx = reflect_index(x + dx, side);
            values[static_cast<std::size_t>(count++)] = image[static_cast<std::size_t>(sy * side + sx)];
        }
    }
    for (int pass = 0; pass < 7; ++pass)
        for (int index = 0; index < 7 - pass; ++index)
            if (values[static_cast<std::size_t>(index)] > values[static_cast<std::size_t>(index + 1)])
                std::swap(values[static_cast<std::size_t>(index)], values[static_cast<std::size_t>(index + 1)]);
    return static_cast<std::uint8_t>((values[3] + values[4]) / 2);
}
}

extern "C" std::int64_t mibench_automotive_susan(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || input_length < 2 || input_length > max_parseable_input_length) return -1;
    if (input[0] < min_side || input[0] > max_side) return -1;
    const int side = static_cast<int>(input[0]);
    const std::size_t pixel_count = static_cast<std::size_t>(side * side);
    if (input_length != pixel_count + 1) return -1;
    std::array<std::uint8_t, 256> image{};
    for (std::size_t index = 0; index < pixel_count; ++index) {
        const std::int64_t pixel = input[index + 1];
        if (pixel < 0 || pixel > 255) return -1;
        image[index] = static_cast<std::uint8_t>(pixel);
    }
    if (output == nullptr || output_capacity < pixel_count) return -2;

    std::array<int, 511> brightness{};
    std::array<int, 225> distance{};
    setup_weights(brightness, distance);
    for (int y = 0; y < side; ++y) {
        for (int x = 0; x < side; ++x) {
            const int center = image[static_cast<std::size_t>(y * side + x)];
            int area = 0;
            int total = 0;
            std::size_t mask_index = 0;
            for (int dy = -mask_radius; dy <= mask_radius; ++dy) {
                const int sy = reflect_index(y + dy, side);
                for (int dx = -mask_radius; dx <= mask_radius; ++dx) {
                    const int sx = reflect_index(x + dx, side);
                    const int pixel = image[static_cast<std::size_t>(sy * side + sx)];
                    const int contribution = distance[mask_index++] * brightness[static_cast<std::size_t>(center - pixel + 255)];
                    area += contribution;
                    total += contribution * pixel;
                }
            }
            const int denominator = area - 10000;
            output[static_cast<std::size_t>(y * side + x)] = denominator == 0
                ? median_eight(image, side, y, x)
                : static_cast<std::uint8_t>((total - center * 10000) / denominator);
        }
    }
    return static_cast<std::int64_t>(pixel_count);
}
