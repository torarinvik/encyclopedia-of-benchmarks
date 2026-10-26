/*
 * Independent bounded port of the GSM RPE grid-positioning operation.
 * Source attribution and redistribution notice:
 * Copyright 1992, 1993, 1994 by Jutta Degener and Carsten Bormann,
 * Technische Universitaet Berlin
 *
 * Any use of this software is permitted provided that this notice is not
 * removed and that neither the authors nor the Technische Universitaet Berlin
 * are deemed to have made any representations as to the suitability of this
 * software for any purpose nor are held responsible for any defects of this
 * software. THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 * As a matter of courtesy, the authors request to be informed about uses
 * this software has found, about bugs in this software, and about any
 * improvements that may be of general interest.
 *
 * Berlin, 28.11.1994
 * Jutta Degener
 * Carsten Bormann
 */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t input_count = 14;
constexpr std::size_t max_input_length = 15;
constexpr std::size_t output_count = 40;
constexpr std::size_t output_bytes = output_count * 2;

void store_i16_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept
{
    const std::uint16_t bits = static_cast<std::uint16_t>(value);
    output[offset] = static_cast<std::uint8_t>(bits & 255u);
    output[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
}
}

extern "C" std::int64_t mediabench_gsm_rpe_grid_positioning(
    const std::int64_t* input, std::size_t input_length,
    std::uint8_t* output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length == 0 || input_length > max_input_length) return -1;
    if (input_length != input_count || input[0] < 0 || input[0] > 3) return -1;
    for (std::size_t index = 1; index < input_count; ++index)
        if (input[index] < -32768 || input[index] > 32767) return -1;

    std::array<std::int64_t, output_count> staged{};
    const std::size_t grid = static_cast<std::size_t>(input[0]);
    for (std::size_t index = 0; index < 13; ++index)
        staged[grid + 3 * index] = input[index + 1];
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < output_count; ++index)
        store_i16_le(output, 2 * index, staged[index]);
    return static_cast<std::int64_t>(output_bytes);
}
