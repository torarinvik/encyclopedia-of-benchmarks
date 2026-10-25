/*
 * Copyright (c) 2012-2013 Argonne National Laboratory
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid = -1.0e300;
constexpr double scale_q = 1'000'000.0;
constexpr int max_nuclides = 4;
constexpr int min_gridpoints = 2;
constexpr int max_gridpoints = 5;
constexpr std::size_t max_union_points = max_nuclides * max_gridpoints;
constexpr std::size_t max_length = 232;
constexpr int channels = 5;
constexpr int record_size = 6;

double decode(std::int64_t raw) { return static_cast<double>(raw) / scale_q; }

int binary_search(const std::array<std::array<std::int64_t, max_gridpoints>, max_nuclides>& grids,
                  int nuclide, int count, std::int64_t quarry) {
    int minimum = 0;
    int maximum = count - 1;
    if (grids[nuclide][0] > quarry) return 0;
    if (grids[nuclide][count - 1] < quarry) return count - 2;
    while (maximum >= minimum) {
        const int middle = minimum + (maximum - minimum) / 2;
        if (grids[nuclide][middle] < quarry) minimum = middle + 1;
        else if (grids[nuclide][middle] > quarry) maximum = middle - 1;
        else return middle;
    }
    return maximum;
}

std::size_t grid_search(const std::array<std::int64_t, max_union_points>& grid,
                        std::size_t count, std::int64_t quarry) {
    std::size_t lower = 0, upper = count - 1;
    std::size_t span = upper - lower;
    while (span > 1) {
        const std::size_t middle = lower + span / 2;
        if (grid[middle] > quarry) upper = middle;
        else lower = middle;
        span = upper - lower;
    }
    return lower;
}
}

extern "C" double doe_xsbench_unionized_macro_xs(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 22 || length > max_length) return invalid;
    const std::int64_t nuclides_raw = input[0], gridpoints_raw = input[1];
    const std::int64_t material_nuclides_raw = input[2], query_raw = input[3];
    if (nuclides_raw < 1 || nuclides_raw > max_nuclides ||
        gridpoints_raw < min_gridpoints || gridpoints_raw > max_gridpoints ||
        material_nuclides_raw < 1 || material_nuclides_raw > nuclides_raw ||
        query_raw < 0 || query_raw > 1'000'000) return invalid;

    const std::size_t nuclides = static_cast<std::size_t>(nuclides_raw);
    const std::size_t gridpoints = static_cast<std::size_t>(gridpoints_raw);
    const std::size_t material_nuclides = static_cast<std::size_t>(material_nuclides_raw);
    const std::size_t union_points = nuclides * gridpoints;
    const std::size_t composition_start = 4;
    const std::size_t union_start = composition_start + 2 * material_nuclides;
    const std::size_t pointer_start = union_start + union_points;
    const std::size_t grid_start = pointer_start + union_points * nuclides;
    const std::size_t expected_length = grid_start + union_points * record_size;
    if (length != expected_length) return invalid;

    std::array<int, max_nuclides> composition_ids{};
    std::array<double, max_nuclides> concentrations{};
    std::array<bool, max_nuclides> used{};
    for (std::size_t i = 0; i < material_nuclides; ++i) {
        const std::int64_t id = input[composition_start + 2 * i];
        const std::int64_t concentration = input[composition_start + 2 * i + 1];
        if (id < 0 || id >= nuclides_raw || concentration < 0 || concentration > 1'000'000)
            return invalid;
        if (used[static_cast<std::size_t>(id)]) return invalid;
        used[static_cast<std::size_t>(id)] = true;
        composition_ids[i] = static_cast<int>(id);
        concentrations[i] = decode(concentration);
    }

    std::array<std::int64_t, max_union_points> union_grid{};
    for (std::size_t i = 0; i < union_points; ++i) {
        const std::int64_t energy = input[union_start + i];
        if (energy < 0 || energy > 1'000'000 || (i > 0 && energy <= union_grid[i - 1]))
            return invalid;
        union_grid[i] = energy;
    }

    std::array<std::array<std::int64_t, max_gridpoints>, max_nuclides> nuclide_energies{};
    for (std::size_t n = 0; n < nuclides; ++n) {
        for (std::size_t p = 0; p < gridpoints; ++p) {
            const std::size_t record = grid_start + (n * gridpoints + p) * record_size;
            const std::int64_t energy = input[record];
            if (energy < 0 || energy > 1'000'000 ||
                (p > 0 && energy <= nuclide_energies[n][p - 1])) return invalid;
            nuclide_energies[n][p] = energy;
            for (std::size_t channel = 1; channel < record_size; ++channel)
                if (input[record + channel] < 0 || input[record + channel] > 1'000'000) return invalid;
        }
    }

    for (std::size_t u = 0; u < union_points; ++u) {
        int matches = 0;
        for (std::size_t n = 0; n < nuclides; ++n)
            for (std::size_t p = 0; p < gridpoints; ++p)
                if (nuclide_energies[n][p] == union_grid[u]) ++matches;
        if (matches != 1) return invalid;
        for (std::size_t n = 0; n < nuclides; ++n) {
            const std::int64_t pointer = input[pointer_start + u * nuclides + n];
            if (pointer != binary_search(nuclide_energies, static_cast<int>(n),
                                         static_cast<int>(gridpoints), union_grid[u])) return invalid;
        }
    }

    const std::size_t query_index = grid_search(union_grid, union_points, query_raw);
    std::array<double, channels> macro{};
    const double query = decode(query_raw);
    for (std::size_t m = 0; m < material_nuclides; ++m) {
        const std::size_t nuclide = static_cast<std::size_t>(composition_ids[m]);
        const std::int64_t pointer = input[pointer_start + query_index * nuclides + nuclide];
        const std::size_t low_index = pointer == static_cast<std::int64_t>(gridpoints - 1)
            ? static_cast<std::size_t>(pointer - 1) : static_cast<std::size_t>(pointer);
        const std::size_t low_record = grid_start + (nuclide * gridpoints + low_index) * record_size;
        const std::size_t high_record = low_record + record_size;
        const double low_energy = decode(input[low_record]);
        const double high_energy = decode(input[high_record]);
        const double factor = (high_energy - query) / (high_energy - low_energy);
        for (std::size_t channel = 0; channel < channels; ++channel) {
            const double low_xs = decode(input[low_record + channel + 1]);
            const double high_xs = decode(input[high_record + channel + 1]);
            const double microscopic = high_xs - factor * (high_xs - low_xs);
            macro[channel] += microscopic * concentrations[m];
        }
    }
    return macro[0] + 2.0 * macro[1] + 3.0 * macro[2] + 5.0 * macro[3] + 7.0 * macro[4];
}
