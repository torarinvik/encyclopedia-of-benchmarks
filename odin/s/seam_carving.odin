// Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
// Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
package seam_carving

import "core:c"
import "core:math"

@(export)
seam_carving :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 39 do return -1
    width_value, height_value := input[0], input[1]
    if width_value < 2 || width_value > 6 || height_value < 1 || height_value > 6 do return -1
    width := c.size_t(width_value)
    height := c.size_t(height_value)
    if length != 2 + width * height do return -1
    for index: c.size_t = 0; index < width * height; index += 1 {
        if input[2 + index] < 0 || input[2 + index] > 255 do return -1
    }

    energy: [6][6]f64 = {}
    cumulative: [6][6]f64 = {}
    previous_x: [6][6]i64 = {}
    seam_x: [6]c.size_t = {}
    for y: c.size_t = 0; y < height; y += 1 {
        row := y * width
        for x: c.size_t = 0; x < width; x += 1 {
            middle := f64(input[2 + row + x])
            left_energy, right_energy := f64(0), f64(0)
            if x > 0 {
                difference := f64(input[2 + row + x - 1]) - middle
                left_energy = difference * difference + difference * difference + difference * difference
            }
            if x + 1 < width {
                difference := f64(input[2 + row + x + 1]) - middle
                right_energy = difference * difference + difference * difference + difference * difference
            }
            energy[y][x] = math.sqrt(left_energy + right_energy)
        }
    }
    for x: c.size_t = 0; x < width; x += 1 { cumulative[0][x] = energy[0][x] }
    for y: c.size_t = 1; y < height; y += 1 {
        for x: c.size_t = 0; x < width; x += 1 {
            minimum := f64(1.0e300)
            best_x := x
            start := c.size_t(0)
            if x > 0 { start = x - 1 }
            end := x + 1
            if end >= width { end = width - 1 }
            for candidate := start; candidate <= end; candidate += 1 {
                if cumulative[y - 1][candidate] < minimum {
                    minimum = cumulative[y - 1][candidate]
                    best_x = candidate
                }
            }
            cumulative[y][x] = minimum + energy[y][x]
            previous_x[y][x] = i64(best_x)
        }
    }
    last_x := c.size_t(0)
    minimum := cumulative[height - 1][0]
    for x: c.size_t = 1; x < width; x += 1 {
        if cumulative[height - 1][x] < minimum {
            minimum = cumulative[height - 1][x]
            last_x = x
        }
    }
    seam_x[height - 1] = last_x
    y := height - 1
    for y > 0 {
        seam_x[y - 1] = c.size_t(previous_x[y][seam_x[y]])
        y -= 1
    }

    needed := height * (width - 1)
    if output == nil || output_capacity < needed do return -2
    staged: [30]u8 = {}
    position := c.size_t(0)
    for row_index: c.size_t = 0; row_index < height; row_index += 1 {
        for x: c.size_t = 0; x < width; x += 1 {
            if x != seam_x[row_index] {
                staged[position] = u8(input[2 + row_index * width + x])
                position += 1
            }
        }
    }
    for index: c.size_t = 0; index < needed; index += 1 { output[index] = staged[index] }
    return i64(needed)
}
