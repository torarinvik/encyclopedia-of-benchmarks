/*
 * Copyright (c) 2012-2013 Argonne National Laboratory
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
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

#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SCALE_Q 1000000.0
#define MAX_NUCLIDES 4
#define MIN_GRIDPOINTS 2
#define MAX_GRIDPOINTS 5
#define MAX_UNION_POINTS (MAX_NUCLIDES * MAX_GRIDPOINTS)
#define MAX_LENGTH 232
#define CHANNELS 5
#define RECORD_SIZE 6

static double decode(int64_t raw) { return (double)raw / SCALE_Q; }

static int binary_search(const int64_t *grid, int count, int64_t quarry) {
    int minimum = 0;
    int maximum = count - 1;
    if (grid[0] > quarry) return 0;
    if (grid[count - 1] < quarry) return count - 2;
    while (maximum >= minimum) {
        const int middle = minimum + (maximum - minimum) / 2;
        if (grid[middle] < quarry) minimum = middle + 1;
        else if (grid[middle] > quarry) maximum = middle - 1;
        else return middle;
    }
    return maximum;
}

static size_t grid_search(const int64_t *grid, size_t count, int64_t quarry) {
    size_t lower = 0;
    size_t upper = count - 1;
    size_t span = upper - lower;
    while (span > 1) {
        const size_t middle = lower + span / 2;
        if (grid[middle] > quarry) upper = middle;
        else lower = middle;
        span = upper - lower;
    }
    return lower;
}

double doe_xsbench_unionized_macro_xs(const int64_t *input, size_t length) {
    if (input == NULL || length < 22 || length > MAX_LENGTH) return INVALID_RESULT;
    const int64_t nuclides_raw = input[0];
    const int64_t gridpoints_raw = input[1];
    const int64_t material_nuclides_raw = input[2];
    const int64_t query_raw = input[3];
    if (nuclides_raw < 1 || nuclides_raw > MAX_NUCLIDES ||
        gridpoints_raw < MIN_GRIDPOINTS || gridpoints_raw > MAX_GRIDPOINTS ||
        material_nuclides_raw < 1 || material_nuclides_raw > nuclides_raw ||
        query_raw < 0 || query_raw > 1000000) return INVALID_RESULT;

    const size_t nuclides = (size_t)nuclides_raw;
    const size_t gridpoints = (size_t)gridpoints_raw;
    const size_t material_nuclides = (size_t)material_nuclides_raw;
    const size_t union_points = nuclides * gridpoints;
    const size_t composition_start = 4;
    const size_t union_start = composition_start + 2 * material_nuclides;
    const size_t pointer_start = union_start + union_points;
    const size_t grid_start = pointer_start + union_points * nuclides;
    const size_t expected_length = grid_start + union_points * RECORD_SIZE;
    if (length != expected_length) return INVALID_RESULT;

    int composition_ids[MAX_NUCLIDES] = {0};
    double concentrations[MAX_NUCLIDES] = {0.0};
    int used[MAX_NUCLIDES] = {0};
    for (size_t i = 0; i < material_nuclides; ++i) {
        const int64_t id_raw = input[composition_start + 2 * i];
        const int64_t concentration_raw = input[composition_start + 2 * i + 1];
        if (id_raw < 0 || id_raw >= nuclides_raw || concentration_raw < 0 || concentration_raw > 1000000)
            return INVALID_RESULT;
        if (used[(size_t)id_raw]) return INVALID_RESULT;
        used[(size_t)id_raw] = 1;
        composition_ids[i] = (int)id_raw;
        concentrations[i] = decode(concentration_raw);
    }

    int64_t union_grid[MAX_UNION_POINTS];
    for (size_t i = 0; i < union_points; ++i) {
        const int64_t energy = input[union_start + i];
        if (energy < 0 || energy > 1000000 || (i > 0 && energy <= union_grid[i - 1]))
            return INVALID_RESULT;
        union_grid[i] = energy;
    }

    int64_t nuclide_energies[MAX_NUCLIDES][MAX_GRIDPOINTS] = {{0}};
    for (size_t n = 0; n < nuclides; ++n) {
        for (size_t p = 0; p < gridpoints; ++p) {
            const size_t record = grid_start + (n * gridpoints + p) * RECORD_SIZE;
            const int64_t energy = input[record];
            if (energy < 0 || energy > 1000000 ||
                (p > 0 && energy <= nuclide_energies[n][p - 1])) return INVALID_RESULT;
            nuclide_energies[n][p] = energy;
            for (size_t channel = 1; channel < RECORD_SIZE; ++channel) {
                if (input[record + channel] < 0 || input[record + channel] > 1000000)
                    return INVALID_RESULT;
            }
        }
    }

    for (size_t u = 0; u < union_points; ++u) {
        int matches = 0;
        for (size_t n = 0; n < nuclides; ++n)
            for (size_t p = 0; p < gridpoints; ++p)
                if (nuclide_energies[n][p] == union_grid[u]) ++matches;
        if (matches != 1) return INVALID_RESULT;
        for (size_t n = 0; n < nuclides; ++n) {
            const int64_t pointer = input[pointer_start + u * nuclides + n];
            if (pointer != binary_search(nuclide_energies[n], (int)gridpoints, union_grid[u]))
                return INVALID_RESULT;
        }
    }

    const size_t query_index = grid_search(union_grid, union_points, query_raw);
    double macro[CHANNELS] = {0.0, 0.0, 0.0, 0.0, 0.0};
    const double query = decode(query_raw);
    for (size_t m = 0; m < material_nuclides; ++m) {
        const size_t nuclide = (size_t)composition_ids[m];
        const int64_t pointer = input[pointer_start + query_index * nuclides + nuclide];
        const size_t low_index = pointer == gridpoints - 1 ? (size_t)pointer - 1 : (size_t)pointer;
        const size_t low_record = grid_start + (nuclide * gridpoints + low_index) * RECORD_SIZE;
        const size_t high_record = low_record + RECORD_SIZE;
        const double low_energy = decode(input[low_record]);
        const double high_energy = decode(input[high_record]);
        const double factor = (high_energy - query) / (high_energy - low_energy);
        for (size_t channel = 0; channel < CHANNELS; ++channel) {
            const double low_xs = decode(input[low_record + channel + 1]);
            const double high_xs = decode(input[high_record + channel + 1]);
            const double microscopic = high_xs - factor * (high_xs - low_xs);
            macro[channel] += microscopic * concentrations[m];
        }
    }
    return macro[0] + 2.0 * macro[1] + 3.0 * macro[2] + 5.0 * macro[3] + 7.0 * macro[4];
}
