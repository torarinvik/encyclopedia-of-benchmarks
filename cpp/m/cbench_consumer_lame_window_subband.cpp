/*
 * Copyright (c) 1999 Takehiro TOMINAGA
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t sample_count = 511, window_count = 256, input_count = 767;
constexpr std::size_t max_input_length = 768, band_count = 32, output_bytes = 256;
constexpr double pi = 3.14159265358979323846264338327950288;
constexpr int s_offsets[15] = {334,398,462,14,78,142,206,16,80,144,208,272,336,400,464};
constexpr int t_offsets[15] = {176,112,48,496,432,368,304,494,430,366,302,238,174,110,46};

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}

std::int64_t round_q1000(double value) noexcept {
    const double scaled = value * 1000.0;
    const double magnitude = scaled < 0.0 ? -scaled : scaled;
    const auto rounded = static_cast<std::int64_t>(magnitude + 0.5);
    return scaled < 0.0 ? -rounded : rounded;
}

bool valid(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length == 0 || length > max_input_length || length != input_count) return false;
    for (std::size_t i = 0; i < sample_count; ++i)
        if (input[i] < -32768 || input[i] > 32767) return false;
    for (std::size_t i = 0; i < window_count; ++i)
        if (input[sample_count + i] < -4500000 || input[sample_count + i] > 36000000) return false;
    for (std::size_t i = 0; i < window_count; ++i)
        if ((i == 0 || (i >= 8 && (i - 8) % 16 == 0)) && input[sample_count + i] <= 25000000) return false;
    return true;
}

void window_subband(const std::int64_t* input, std::array<double, window_count>& window,
                   std::array<double, band_count>& bands) {
    const double maximum = window[248];
    std::array<double, 31> mmax{};
    std::array<std::array<double, 31>, 16> mm{};
    std::size_t wp = 0, wr = 0;
    double w = window[wp++];
    mmax[15] = w / maximum;
    for (std::size_t k = 0; k < 7; ++k) window[wr++] = window[wp++] / w;
    for (int i = 14; i >= 0; --i) {
        w = window[wp++];
        mmax[static_cast<std::size_t>(i)] = w / maximum;
        mmax[static_cast<std::size_t>(30 - i)] = w / maximum;
        for (std::size_t k = 0; k < 15; ++k) window[wr++] = window[wp++] / w;
    }
    ++wp;
    for (std::size_t k = 0; k < 7; ++k) window[wr++] = window[wp++] / maximum;
    for (int i = 15; i >= 0; --i)
        for (int k = 1; k < 32; ++k)
            mm[static_cast<std::size_t>(i)][static_cast<std::size_t>(k - 1)] =
                std::cos((2 * i + 1) * k * pi / 64.0) * mmax[static_cast<std::size_t>(k - 1)];

    std::array<double, 31> inner{};
    std::size_t coeff = 0;
    double t = static_cast<double>(input[255]);
    t += static_cast<double>(input[223] - input[287]) * window[coeff++];
    t += static_cast<double>(input[191] + input[319]) * window[coeff++];
    t += static_cast<double>(input[159] - input[351]) * window[coeff++];
    t += static_cast<double>(input[127] + input[383]) * window[coeff++];
    t += static_cast<double>(input[95] - input[415]) * window[coeff++];
    t += static_cast<double>(input[63] + input[447]) * window[coeff++];
    t += static_cast<double>(input[31] - input[479]) * window[coeff++];
    inner[15] = t;
    for (int i = 14; i >= 0; --i) {
        double s = static_cast<double>(input[static_cast<std::size_t>(270 - i)]);
        t = static_cast<double>(input[static_cast<std::size_t>(240 + i)]);
        for (int k = 0; k < 15; ++k) {
            w = window[coeff++];
            const auto sk = static_cast<std::size_t>(s_offsets[k] + (k < 7 ? -i : i));
            const auto tk = static_cast<std::size_t>(t_offsets[k] + (k < 7 ? i : -i));
            const double sv = static_cast<double>(input[sk]) * w;
            const double tv = static_cast<double>(input[tk]) * w;
            if (k >= 11) s -= sv; else s += sv;
            if (k >= 7 && k < 11) t -= tv; else t += tv;
        }
        inner[static_cast<std::size_t>(30 - i)] = s;
        inner[static_cast<std::size_t>(i)] = t;
    }
    double s = static_cast<double>(input[239]);
    s += static_cast<double>(input[175]) * window[coeff++];
    s += static_cast<double>(input[111]) * window[coeff++];
    s += static_cast<double>(input[47]) * window[coeff++];
    s -= static_cast<double>(input[303]) * window[coeff++];
    s -= static_cast<double>(input[367]) * window[coeff++];
    s -= static_cast<double>(input[431]) * window[coeff++];
    s -= static_cast<double>(input[495]) * window[coeff++];
    for (int i = 15; i >= 0; --i) {
        double s0 = s, s1 = t * mm[static_cast<std::size_t>(i)][0];
        std::size_t at = 1;
        for (int j = 0; j < 15; ++j) {
            s0 += mm[static_cast<std::size_t>(i)][2 * j + 1] * inner[at++];
            s1 += mm[static_cast<std::size_t>(i)][2 * j + 2] * inner[at++];
        }
        bands[static_cast<std::size_t>(i)] = s0 + s1;
        bands[static_cast<std::size_t>(31 - i)] = s0 - s1;
    }
}
}

extern "C" std::int64_t cbench_consumer_lame_window_subband(
    const std::int64_t* input, std::size_t input_length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (!valid(input, input_length)) return -1;
    std::array<double, window_count> window{};
    for (std::size_t i = 0; i < window_count; ++i)
        window[i] = static_cast<double>(input[sample_count + i]) / 1000000000.0;
    std::array<double, band_count> bands{};
    window_subband(input, window, bands);
    std::array<std::int64_t, band_count> staged{};
    for (std::size_t i = 0; i < band_count; ++i) staged[i] = round_q1000(bands[i]);
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < band_count; ++i) store_i64_le(output, 8 * i, staged[i]);
    return static_cast<std::int64_t>(output_bytes);
}
