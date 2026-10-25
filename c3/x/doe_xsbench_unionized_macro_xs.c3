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

module doe_xsbench_unionized_macro_xs;

const double INVALID_RESULT = -1e300;
const double SCALE_Q = 1000000.0;
const long MAX_NUCLIDES = 4;
const long MIN_GRIDPOINTS = 2;
const long MAX_GRIDPOINTS = 5;
const usz MAX_UNION_POINTS = 20;
const usz MAX_LENGTH = 232;
const usz RECORD_SIZE = 6;

fn double decode(long raw) { return (double)raw / SCALE_Q; }

fn long binary_search(long* energies, usz nuclide, usz gridpoints, long quarry) {
    long minimum = 0;
    long maximum = (long)gridpoints - 1;
    usz first_index = nuclide * (usz)MAX_GRIDPOINTS;
    if (energies[first_index] > quarry) return 0;
    if (energies[first_index + gridpoints - 1] < quarry) return (long)gridpoints - 2;
    while (maximum >= minimum) {
        long middle = minimum + (maximum - minimum) / 2;
        long energy = energies[first_index + (usz)middle];
        if (energy < quarry) minimum = middle + 1;
        else if (energy > quarry) maximum = middle - 1;
        else return middle;
    }
    return maximum;
}

fn usz grid_search(long* grid, usz count, long quarry) {
    usz lower = 0;
    usz upper = count - 1;
    usz span = upper - lower;
    while (span > 1) {
        usz middle = lower + span / 2;
        if (grid[middle] > quarry) upper = middle;
        else lower = middle;
        span = upper - lower;
    }
    return lower;
}

fn double doe_xsbench_unionized_macro_xs(long* input, usz length) @export("doe_xsbench_unionized_macro_xs") {
    if (input == null || length < 22 || length > MAX_LENGTH) return INVALID_RESULT;
    long nuclides_raw = input[0], gridpoints_raw = input[1];
    long material_nuclides_raw = input[2], query_raw = input[3];
    if (nuclides_raw < 1 || nuclides_raw > MAX_NUCLIDES ||
        gridpoints_raw < MIN_GRIDPOINTS || gridpoints_raw > MAX_GRIDPOINTS ||
        material_nuclides_raw < 1 || material_nuclides_raw > nuclides_raw ||
        query_raw < 0 || query_raw > 1000000) return INVALID_RESULT;

    usz nuclides = (usz)nuclides_raw;
    usz gridpoints = (usz)gridpoints_raw;
    usz material_nuclides = (usz)material_nuclides_raw;
    usz union_points = nuclides * gridpoints;
    usz composition_start = 4;
    usz union_start = composition_start + 2 * material_nuclides;
    usz pointer_start = union_start + union_points;
    usz grid_start = pointer_start + union_points * nuclides;
    if (length != grid_start + union_points * RECORD_SIZE) return INVALID_RESULT;

    long[MAX_NUCLIDES] composition_ids = zeroed;
    double[MAX_NUCLIDES] concentrations = zeroed;
    bool[MAX_NUCLIDES] used = zeroed;
    for (usz item = 0; item < material_nuclides; item++) {
        long id_raw = input[composition_start + 2 * item];
        long concentration_raw = input[composition_start + 2 * item + 1];
        if (id_raw < 0 || id_raw >= nuclides_raw || concentration_raw < 0 || concentration_raw > 1000000)
            return INVALID_RESULT;
        if (used[(usz)id_raw]) return INVALID_RESULT;
        used[(usz)id_raw] = true;
        composition_ids[item] = id_raw;
        concentrations[item] = decode(concentration_raw);
    }

    long[MAX_UNION_POINTS] union_grid = zeroed;
    for (usz index = 0; index < union_points; index++) {
        long energy = input[union_start + index];
        if (energy < 0 || energy > 1000000 || (index > 0 && energy <= union_grid[index - 1]))
            return INVALID_RESULT;
        union_grid[index] = energy;
    }

    long[MAX_NUCLIDES * MAX_GRIDPOINTS] nuclide_energies = zeroed;
    for (usz nuclide = 0; nuclide < nuclides; nuclide++) {
        for (usz point = 0; point < gridpoints; point++) {
            usz record = grid_start + (nuclide * gridpoints + point) * RECORD_SIZE;
            long energy = input[record];
            usz energy_slot = nuclide * (usz)MAX_GRIDPOINTS + point;
            if (energy < 0 || energy > 1000000 ||
                (point > 0 && energy <= nuclide_energies[energy_slot - 1])) return INVALID_RESULT;
            nuclide_energies[energy_slot] = energy;
            for (usz channel = 1; channel < RECORD_SIZE; channel++)
                if (input[record + channel] < 0 || input[record + channel] > 1000000) return INVALID_RESULT;
        }
    }

    for (usz union_index = 0; union_index < union_points; union_index++) {
        usz matches = 0;
        for (usz nuclide = 0; nuclide < nuclides; nuclide++)
            for (usz point = 0; point < gridpoints; point++)
                if (nuclide_energies[nuclide * (usz)MAX_GRIDPOINTS + point] == union_grid[union_index]) matches++;
        if (matches != 1) return INVALID_RESULT;
        for (usz nuclide = 0; nuclide < nuclides; nuclide++) {
            long pointer = input[pointer_start + union_index * nuclides + nuclide];
            if (pointer != binary_search(nuclide_energies, nuclide, gridpoints, union_grid[union_index]))
                return INVALID_RESULT;
        }
    }

    usz query_index = grid_search(union_grid, union_points, query_raw);
    double[5] macro = zeroed;
    double query = decode(query_raw);
    for (usz item = 0; item < material_nuclides; item++) {
        usz nuclide = (usz)composition_ids[item];
        long pointer = input[pointer_start + query_index * nuclides + nuclide];
        usz low_index = pointer == (long)(gridpoints - 1) ? (usz)(pointer - 1) : (usz)pointer;
        usz low_record = grid_start + (nuclide * gridpoints + low_index) * RECORD_SIZE;
        usz high_record = low_record + RECORD_SIZE;
        double low_energy = decode(input[low_record]);
        double high_energy = decode(input[high_record]);
        double factor = (high_energy - query) / (high_energy - low_energy);
        for (usz channel = 0; channel < 5; channel++) {
            double low_xs = decode(input[low_record + channel + 1]);
            double high_xs = decode(input[high_record + channel + 1]);
            double microscopic = high_xs - factor * (high_xs - low_xs);
            macro[channel] += microscopic * concentrations[item];
        }
    }
    return macro[0] + 2.0 * macro[1] + 3.0 * macro[2] + 5.0 * macro[3] + 7.0 * macro[4];
}
