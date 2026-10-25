#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_DIM = 4, MAX_ATOMS = 4, MAX_INPUT = 25, MAX_GRID = 64;
constexpr float INV_CELL_LENGTH = 0.25f;
struct Atom { float x, y, z, q; };

float decode_component(std::int64_t raw) { return static_cast<float>(raw) / 1000000.0f; }
void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value)
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    output[offset] = static_cast<std::uint8_t>(bits);
    output[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(bits >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(bits >> 24);
}
}

extern "C" std::int64_t parboil_cutcp(const std::int64_t *input, std::size_t input_length,
                                      std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 13 || input_length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4
            || input[2] < 2 || input[2] > 4 || input[3] < 1 || input[3] > 4) return -1;
    const int nx = static_cast<int>(input[0]), ny = static_cast<int>(input[1]);
    const int nz = static_cast<int>(input[2]), natoms = static_cast<int>(input[3]);
    if (input_length != 9 + 4 * natoms) return -1;
    const auto xlo_raw = input[4], ylo_raw = input[5], zlo_raw = input[6];
    const auto spacing_raw = input[7], cutoff_raw = input[8];
    if (xlo_raw < -16000000 || xlo_raw > 16000000
            || ylo_raw < -16000000 || ylo_raw > 16000000
            || zlo_raw < -16000000 || zlo_raw > 16000000
            || xlo_raw % 1000000 != 0 || ylo_raw % 1000000 != 0 || zlo_raw % 1000000 != 0
            || spacing_raw < 1000000 || spacing_raw > 4000000 || spacing_raw % 1000000 != 0
            || cutoff_raw < 250000 || cutoff_raw > 4000000) return -1;
    for (int n = 0; n < natoms; ++n) {
        const std::size_t offset = 9 + 4 * static_cast<std::size_t>(n);
        if (input[offset] < 0 || input[offset] >= nx - 1
                || input[offset + 1] < 0 || input[offset + 1] >= ny - 1
                || input[offset + 2] < 0 || input[offset + 2] >= nz - 1
                || input[offset + 3] < -1000000 || input[offset + 3] > 1000000) return -1;
    }
    const std::size_t points = static_cast<std::size_t>(nx) * ny * nz;
    const std::size_t output_bytes = 4 * points;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    const float xlo = decode_component(xlo_raw), ylo = decode_component(ylo_raw);
    const float zlo = decode_component(zlo_raw), spacing = decode_component(spacing_raw);
    const float cutoff = decode_component(cutoff_raw), half_spacing = spacing * 0.5f;
    Atom atoms[MAX_ATOMS];
    for (int n = 0; n < natoms; ++n) {
        const std::size_t offset = 9 + 4 * static_cast<std::size_t>(n);
        const int ix = static_cast<int>(input[offset]), iy = static_cast<int>(input[offset + 1]);
        const int iz = static_cast<int>(input[offset + 2]);
        atoms[n] = {xlo + (static_cast<float>(ix) * spacing + half_spacing),
                    ylo + (static_cast<float>(iy) * spacing + half_spacing),
                    zlo + (static_cast<float>(iz) * spacing + half_spacing),
                    decode_component(input[offset + 3])};
    }
    float min_x = atoms[0].x, max_x = atoms[0].x;
    float min_y = atoms[0].y, max_y = atoms[0].y;
    float min_z = atoms[0].z, max_z = atoms[0].z;
    for (int n = 1; n < natoms; ++n) {
        if (atoms[n].x < min_x) min_x = atoms[n].x;
        if (atoms[n].x > max_x) max_x = atoms[n].x;
        if (atoms[n].y < min_y) min_y = atoms[n].y;
        if (atoms[n].y > max_y) max_y = atoms[n].y;
        if (atoms[n].z < min_z) min_z = atoms[n].z;
        if (atoms[n].z > max_z) max_z = atoms[n].z;
    }
    const int nx_cell = static_cast<int>(std::floor((max_x - min_x) * INV_CELL_LENGTH)) + 1;
    const int ny_cell = static_cast<int>(std::floor((max_y - min_y) * INV_CELL_LENGTH)) + 1;
    const int nz_cell = static_cast<int>(std::floor((max_z - min_z) * INV_CELL_LENGTH)) + 1;
    const int cell_count = nx_cell * ny_cell * nz_cell;
    int first[MAX_GRID], next[MAX_ATOMS];
    for (int c = 0; c < cell_count; ++c) first[c] = -1;
    for (int n = 0; n < natoms; ++n) next[n] = -1;
    for (int n = 0; n < natoms; ++n) {
        if (atoms[n].q == 0.0f) continue;
        const int i = static_cast<int>(std::floor((atoms[n].x - min_x) * INV_CELL_LENGTH));
        const int j = static_cast<int>(std::floor((atoms[n].y - min_y) * INV_CELL_LENGTH));
        const int k = static_cast<int>(std::floor((atoms[n].z - min_z) * INV_CELL_LENGTH));
        const int cell = (k * ny_cell + j) * nx_cell + i;
        next[n] = first[cell];
        first[cell] = n;
    }

    const float cutoff_squared = cutoff * cutoff;
    const float inv_cutoff_squared = 1.0f / cutoff_squared;
    const float inv_spacing = 1.0f / spacing;
    const int radius = static_cast<int>(std::ceil(cutoff * inv_spacing)) - 1;
    float grid[MAX_GRID]{};
    for (int c = 0; c < cell_count; ++c) {
        for (int n = first[c]; n != -1; n = next[n]) {
            const float x = atoms[n].x - xlo, y = atoms[n].y - ylo, z = atoms[n].z - zlo;
            const float q = atoms[n].q;
            const int ic = static_cast<int>(x * inv_spacing);
            const int jc = static_cast<int>(y * inv_spacing);
            const int kc = static_cast<int>(z * inv_spacing);
            int ia = ic - radius, ib = ic + radius + 1;
            int ja = jc - radius, jb = jc + radius + 1;
            int ka = kc - radius, kb = kc + radius + 1;
            if (ia < 0) ia = 0;
            if (ib >= nx) ib = nx - 1;
            if (ja < 0) ja = 0;
            if (jb >= ny) jb = ny - 1;
            if (ka < 0) ka = 0;
            if (kb >= nz) kb = nz - 1;
            const float xstart = static_cast<float>(ia) * spacing - x;
            const float ystart = static_cast<float>(ja) * spacing - y;
            float dz = static_cast<float>(ka) * spacing - z;
            for (int k = ka; k <= kb; ++k, dz += spacing) {
                const int koff = k * ny;
                const float dz2 = dz * dz;
                float dy = ystart;
                for (int j = ja; j <= jb; ++j, dy += spacing) {
                    const int jkoff = (koff + j) * nx;
                    const float dydz2 = dy * dy + dz2;
                    if (dydz2 >= cutoff_squared) continue;
                    float dx = xstart;
                    for (int i = ia; i <= ib; ++i, dx += spacing) {
                        const float r2 = dx * dx + dydz2;
                        if (r2 >= cutoff_squared) continue;
                        const float s = 1.0f - r2 * inv_cutoff_squared;
                        const float e = q * (1.0f / std::sqrt(r2)) * s * s;
                        grid[jkoff + i] += e;
                    }
                }
            }
        }
    }
    for (std::size_t point = 0; point < points; ++point)
        write_i32_le(output, 4 * point, static_cast<std::int32_t>(std::round(grid[point] * 1000.0f)));
    return static_cast<std::int64_t>(output_bytes);
}
