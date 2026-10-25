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

const INVALID_RESULT: f64 = -1.0e300;
const SCALE_Q: f64 = 1_000_000.0;
const MAX_NUCLIDES: usize = 4;
const MIN_GRIDPOINTS: usize = 2;
const MAX_GRIDPOINTS: usize = 5;
const MAX_UNION_POINTS: usize = MAX_NUCLIDES * MAX_GRIDPOINTS;
const MAX_LENGTH: usize = 232;
const CHANNELS: usize = 5;
const RECORD_SIZE: usize = 6;

#[inline]
fn decode(raw: i64) -> f64 {
    raw as f64 / SCALE_Q
}

fn binary_search(
    grids: &[[i64; MAX_GRIDPOINTS]; MAX_NUCLIDES],
    nuclide: usize,
    count: usize,
    quarry: i64,
) -> i64 {
    let mut minimum: i64 = 0;
    let mut maximum: i64 = count as i64 - 1;
    if grids[nuclide][0] > quarry { return 0; }
    if grids[nuclide][count - 1] < quarry { return count as i64 - 2; }
    while maximum >= minimum {
        let middle = minimum + (maximum - minimum) / 2;
        if grids[nuclide][middle as usize] < quarry { minimum = middle + 1; }
        else if grids[nuclide][middle as usize] > quarry { maximum = middle - 1; }
        else { return middle; }
    }
    maximum
}

fn grid_search(grid: &[i64; MAX_UNION_POINTS], count: usize, quarry: i64) -> usize {
    let mut lower = 0;
    let mut upper = count - 1;
    let mut span = upper - lower;
    while span > 1 {
        let middle = lower + span / 2;
        if grid[middle] > quarry { upper = middle; }
        else { lower = middle; }
        span = upper - lower;
    }
    lower
}

#[no_mangle]
pub unsafe extern "C" fn doe_xsbench_unionized_macro_xs(
    input: *const i64,
    length: usize,
) -> f64 {
    if input.is_null() || length < 22 || length > MAX_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let nuclides_raw = values[0];
    let gridpoints_raw = values[1];
    let material_nuclides_raw = values[2];
    let query_raw = values[3];
    if !(1..=MAX_NUCLIDES as i64).contains(&nuclides_raw)
        || !(MIN_GRIDPOINTS as i64..=MAX_GRIDPOINTS as i64).contains(&gridpoints_raw)
        || material_nuclides_raw < 1 || material_nuclides_raw > nuclides_raw
        || !(0..=1_000_000).contains(&query_raw)
    {
        return INVALID_RESULT;
    }

    let nuclides = nuclides_raw as usize;
    let gridpoints = gridpoints_raw as usize;
    let material_nuclides = material_nuclides_raw as usize;
    let union_points = nuclides * gridpoints;
    let composition_start = 4;
    let union_start = composition_start + 2 * material_nuclides;
    let pointer_start = union_start + union_points;
    let grid_start = pointer_start + union_points * nuclides;
    let expected_length = grid_start + union_points * RECORD_SIZE;
    if length != expected_length { return INVALID_RESULT; }

    let mut composition_ids = [0_usize; MAX_NUCLIDES];
    let mut concentrations = [0.0_f64; MAX_NUCLIDES];
    let mut used = [false; MAX_NUCLIDES];
    for item in 0..material_nuclides {
        let id_raw = values[composition_start + 2 * item];
        let concentration_raw = values[composition_start + 2 * item + 1];
        if id_raw < 0 || id_raw >= nuclides_raw || !(0..=1_000_000).contains(&concentration_raw) {
            return INVALID_RESULT;
        }
        let id = id_raw as usize;
        if used[id] { return INVALID_RESULT; }
        used[id] = true;
        composition_ids[item] = id;
        concentrations[item] = decode(concentration_raw);
    }

    let mut union_grid = [0_i64; MAX_UNION_POINTS];
    for index in 0..union_points {
        let energy = values[union_start + index];
        if !(0..=1_000_000).contains(&energy)
            || (index > 0 && energy <= union_grid[index - 1])
        {
            return INVALID_RESULT;
        }
        union_grid[index] = energy;
    }

    let mut nuclide_energies = [[0_i64; MAX_GRIDPOINTS]; MAX_NUCLIDES];
    for nuclide in 0..nuclides {
        for point in 0..gridpoints {
            let record = grid_start + (nuclide * gridpoints + point) * RECORD_SIZE;
            let energy = values[record];
            if !(0..=1_000_000).contains(&energy)
                || (point > 0 && energy <= nuclide_energies[nuclide][point - 1])
            {
                return INVALID_RESULT;
            }
            nuclide_energies[nuclide][point] = energy;
            for channel in 1..RECORD_SIZE {
                if !(0..=1_000_000).contains(&values[record + channel]) {
                    return INVALID_RESULT;
                }
            }
        }
    }

    for union_index in 0..union_points {
        let mut matches = 0;
        for nuclide in 0..nuclides {
            for point in 0..gridpoints {
                if nuclide_energies[nuclide][point] == union_grid[union_index] { matches += 1; }
            }
        }
        if matches != 1 { return INVALID_RESULT; }
        for nuclide in 0..nuclides {
            let pointer = values[pointer_start + union_index * nuclides + nuclide];
            if pointer != binary_search(&nuclide_energies, nuclide, gridpoints, union_grid[union_index]) {
                return INVALID_RESULT;
            }
        }
    }

    let query_index = grid_search(&union_grid, union_points, query_raw);
    let mut macro_xs = [0.0_f64; CHANNELS];
    let query = decode(query_raw);
    for item in 0..material_nuclides {
        let nuclide = composition_ids[item];
        let pointer = values[pointer_start + query_index * nuclides + nuclide] as usize;
        let low_index = if pointer == gridpoints - 1 { pointer - 1 } else { pointer };
        let low_record = grid_start + (nuclide * gridpoints + low_index) * RECORD_SIZE;
        let high_record = low_record + RECORD_SIZE;
        let low_energy = decode(values[low_record]);
        let high_energy = decode(values[high_record]);
        let factor = (high_energy - query) / (high_energy - low_energy);
        for channel in 0..CHANNELS {
            let low_xs = decode(values[low_record + channel + 1]);
            let high_xs = decode(values[high_record + channel + 1]);
            let microscopic = high_xs - factor * (high_xs - low_xs);
            macro_xs[channel] += microscopic * concentrations[item];
        }
    }
    macro_xs[0] + 2.0 * macro_xs[1] + 3.0 * macro_xs[2] + 5.0 * macro_xs[3] + 7.0 * macro_xs[4]
}
