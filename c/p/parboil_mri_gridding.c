#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define GRID_SIDE 3
#define GRID_CELLS 27
#define MAX_SAMPLES 4
#define MAX_INPUT (1 + 6 * MAX_SAMPLES)

static const float numerator_coefficients[15] = {
    0.210580722890567e-22f, 0.380715242345326e-19f, 0.479440257548300e-16f,
    0.435125971262668e-13f, 0.300931127112960e-10f, 0.160224679395361e-7f,
    0.654858370096785e-5f, 0.202591084143397e-2f, 0.463076284721000e0f,
    0.754337328948189e2f, 0.830792541809429e4f, 0.571661130563785e6f,
    0.216415572361227e8f, 0.356644482244025e9f, 0.144048298227235e10f
};

static float decode(int64_t raw) { return (float)raw / 1000000.0f; }

static float source_kernel(float value) {
    float z = value * value;
    float numerator = numerator_coefficients[0];
    for (int i = 1; i < 15; ++i) {
        float product = z * numerator;
        numerator = product + numerator_coefficients[i];
    }
    float denominator = z - 0.307646912682801e4f;
    denominator = z * denominator;
    denominator = denominator + 0.347626332405882e7f;
    denominator = z * denominator;
    denominator = denominator - 0.144048298227235e10f;
    return -numerator / denominator;
}

static float source_beta(float width, float oversample) {
    float first = 4.0f * width;
    first = first * width;
    float denominator = oversample * oversample;
    first = first / denominator;
    double shifted = (double)oversample - 0.5;
    double argument = (double)first * shifted;
    argument = argument * shifted;
    argument = argument - 0.8;
    return (float)(3.14159265359 * sqrt(argument));
}

static float source_weight(float v, float inverse_cutoff2, float beta, float sdc) {
    float product = v * inverse_cutoff2;
    double radicand = 1.0 - (double)product;
    double argument = (double)beta * sqrt(radicand);
    float kernel_argument = (float)argument;
    float kernel = source_kernel(kernel_argument);
    return kernel * sdc;
}

static int lower_bound(float coordinate, float cutoff) {
    float difference = coordinate - cutoff;
    double value = (double)difference;
    if (value < 0.0) value = 0.0;
    return (int)(uint32_t)value;
}

static int upper_bound(float coordinate, float cutoff) {
    float sum = coordinate + cutoff;
    double value = (double)sum;
    if (value > 2.0) value = 2.0;
    return (int)(uint32_t)value;
}

static int64_t round_away(float value) {
    float scaled = value * 1000.0f;
    float magnitude = scaled < 0.0f ? -scaled : scaled;
    int64_t whole = (int64_t)magnitude;
    if (magnitude - (float)whole >= 0.5f) ++whole;
    return scaled < 0.0f ? -whole : whole;
}

int64_t parboil_mri_gridding(const int64_t *input, size_t length) {
    const float width = 2.5f;
    const float oversample = 0.608933f;
    float real_grid[GRID_CELLS] = {0};
    float imag_grid[GRID_CELLS] = {0};
    float density[GRID_CELLS] = {0};
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    int64_t sample_count = input[0];
    if (sample_count < 0 || sample_count > MAX_SAMPLES || length != (size_t)(1 + 6 * sample_count)) return -1;
    for (int64_t s = 0; s < sample_count; ++s) {
        size_t p = 1 + (size_t)s * 6;
        for (int axis = 0; axis < 3; ++axis)
            if (input[p + (size_t)axis] != 0 && input[p + (size_t)axis] != 1000000 && input[p + (size_t)axis] != 2000000) return -1;
        if (input[p+3] < -1000000 || input[p+3] > 1000000 ||
            input[p+4] < -1000000 || input[p+4] > 1000000 ||
            input[p+5] < 0 || input[p+5] > 1000000) return -1;
    }

    float cutoff = (float)((double)width / 2.0);
    float cutoff2 = cutoff * cutoff;
    float inverse_cutoff2 = 1.0f / cutoff2;
    float beta = source_beta(width, oversample);
    for (int64_t s = 0; s < sample_count; ++s) {
        size_t p = 1 + (size_t)s * 6;
        float kx = decode(input[p]), ky = decode(input[p+1]), kz = decode(input[p+2]);
        float sample_real = decode(input[p+3]), sample_imag = decode(input[p+4]), sdc = decode(input[p+5]);
        if (!(sample_real != 0.0f || sample_imag != 0.0f) || sdc == 0.0f) continue;
        int nx_lo = lower_bound(kx, cutoff), nx_hi = upper_bound(kx, cutoff);
        int ny_lo = lower_bound(ky, cutoff), ny_hi = upper_bound(ky, cutoff);
        int nz_lo = lower_bound(kz, cutoff), nz_hi = upper_bound(kz, cutoff);
        for (int nz = nz_lo; nz <= nz_hi; ++nz) {
            float dz = kz - (float)nz;
            float dz2 = dz * dz;
            if (dz2 < cutoff2) {
                for (int ny = ny_lo; ny <= ny_hi; ++ny) {
                    float dy = ky - (float)ny;
                    float dy2 = dy * dy;
                    float dy2dz2 = dz2 + dy2;
                    if (dy2dz2 < cutoff2) {
                        for (int nx = nx_lo; nx <= nx_hi; ++nx) {
                            float dx = kx - (float)nx;
                            float dx2 = dx * dx;
                            float v = dy2dz2 + dx2;
                            if (v < cutoff2) {
                                int index = nx + GRID_SIDE * ny + GRID_SIDE * GRID_SIDE * nz;
                                float weight = source_weight(v, inverse_cutoff2, beta, sdc);
                                float real_delta = weight * sample_real;
                                float imag_delta = weight * sample_imag;
                                real_grid[index] = real_grid[index] + real_delta;
                                imag_grid[index] = imag_grid[index] + imag_delta;
                                density[index] = (float)((double)density[index] + 1.0);
                            }
                        }
                    }
                }
            }
        }
    }
    int64_t checksum = 0;
    for (int i = 0; i < GRID_CELLS; ++i) {
        int64_t real_q = round_away(real_grid[i]);
        int64_t imag_q = round_away(imag_grid[i]);
        checksum += (int64_t)(i + 1) * (real_q + imag_q + (int64_t)density[i]);
    }
    return checksum;
}
