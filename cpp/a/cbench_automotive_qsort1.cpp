// Modified derivative of cBench automotive_qsort1. Upstream directory notice, verbatim: “Matt wrote this using STL. It is GPL'ed.” The notice does not identify a GPL version. qsort.c copyright (C) 2002 Michael Ringgaard. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 3. Neither the name of the project nor the names of its contributors may be
//    used to endorse or promote products derived from this software without
//    specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <array>
#include <cmath>
#include <cstddef>
#include <utility>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 128;
void shortsort(std::array<std::size_t, max_points>& ids,
               const std::array<double, max_points>& score, std::size_t lo, std::size_t hi) {
    while (hi > lo) {
        std::size_t maximum = lo;
        for (std::size_t p = lo + 1; p <= hi; ++p)
            if (score[ids[p]] > score[ids[maximum]]) maximum = p;
        std::swap(ids[maximum], ids[hi]); --hi;
    }
}
void qsortx(std::array<std::size_t, max_points>& ids,
            const std::array<double, max_points>& score, std::size_t count) {
    std::array<std::size_t, 30> low{}, high{};
    std::size_t sp = 0, lo = 0, hi = count - 1;
    for (;;) {
        const auto size = hi - lo + 1;
        if (size <= 8) shortsort(ids, score, lo, hi);
        else {
            std::swap(ids[lo + size / 2], ids[lo]);
            std::size_t loguy = lo, higuy = hi + 1;
            for (;;) {
                do { ++loguy; } while (loguy <= hi && score[ids[loguy]] <= score[ids[lo]]);
                do { --higuy; } while (higuy > lo && score[ids[higuy]] >= score[ids[lo]]);
                if (higuy < loguy) break;
                std::swap(ids[loguy], ids[higuy]);
            }
            std::swap(ids[lo], ids[higuy]);
            if ((int64_t)higuy - 1 - (int64_t)lo >= (int64_t)hi - (int64_t)loguy) {
                if (lo + 1 < higuy) { low[sp] = lo; high[sp++] = higuy - 1; }
                if (loguy < hi) { lo = loguy; continue; }
            } else {
                if (loguy < hi) { low[sp] = loguy; high[sp++] = hi; }
                if (lo + 1 < higuy) { hi = higuy - 1; continue; }
            }
        }
        if (sp == 0) return;
        --sp; lo = low[sp]; hi = high[sp];
    }
}
}

extern "C" std::int64_t cbench_automotive_qsort1(const std::int64_t* values,
    std::size_t length, std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 4 || length > 385) return -1;
    const auto n_value = values[0];
    if (n_value < 1 || n_value > 128 || length != 1 + 3 * static_cast<std::size_t>(n_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::array<std::array<std::int32_t, 3>, max_points> coords{};
    std::array<std::size_t, max_points> ids{};
    std::array<double, max_points> score{};
    std::array<std::int64_t, max_points> radius2{};
    for (std::size_t i = 0; i < n; ++i) {
        std::int64_t sum = 0;
        for (std::size_t a = 0; a < 3; ++a) {
            const auto v = values[1 + 3 * i + a];
            if (v < -1000000 || v > 1000000) return -1;
            coords[i][a] = static_cast<std::int32_t>(v); sum += v * v;
        }
        for (std::size_t j = 0; j < i; ++j) if (radius2[j] == sum) return -1;
        radius2[i] = sum; ids[i] = i;
        score[i] = std::sqrt(std::pow(static_cast<double>(coords[i][0]), 2.0) +
                             std::pow(static_cast<double>(coords[i][1]), 2.0) +
                             std::pow(static_cast<double>(coords[i][2]), 2.0));
    }
    if (output == nullptr || output_capacity < 12 * n) return -2;
    qsortx(ids, score, n);
    std::array<std::uint8_t, max_points * 12> staged{};
    for (std::size_t r = 0; r < n; ++r) for (std::size_t a = 0; a < 3; ++a) {
        const auto bits = static_cast<std::uint32_t>(coords[ids[r]][a]);
        for (std::size_t b = 0; b < 4; ++b) staged[12*r+4*a+b] = static_cast<std::uint8_t>(bits >> (8*b));
    }
    for (std::size_t i = 0; i < 12*n; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(12*n);
}
