/* Bounded port of the pinned Java Xiaolin Wu line rasterizer. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define COORDINATE_LIMIT INT64_C(64)
#define MAX_PIXELS 258

typedef struct {
    int32_t x;
    int32_t y;
    double intensity;
} Pixel;

typedef struct {
    int x_pixel;
    int y_pixel;
    double y_end;
    double x_gap;
} Endpoint;

static double fraction_part(double value) {
    return value - floor(value);
}

static double reverse_fraction_part(double value) {
    return 1.0 - fraction_part(value);
}

static void add_pixel(Pixel pixels[MAX_PIXELS], size_t *count, int x, int y,
                      double intensity, int steep) {
    if (steep) {
        const int temporary = x;
        x = y;
        y = temporary;
    }
    if (intensity < 0.0) intensity = 0.0;
    if (intensity > 1.0) intensity = 1.0;
    pixels[*count] = (Pixel){(int32_t)x, (int32_t)y, intensity};
    ++*count;
}

static Endpoint process_endpoint(double x, double y, double gradient, int is_start) {
    const double x_end = floor(x + 0.5);
    const double y_end = y + gradient * (x_end - x);
    const double x_gap = is_start ? reverse_fraction_part(x + 0.5) : fraction_part(x + 0.5);
    return (Endpoint){(int)x_end, (int)floor(y_end), y_end, x_gap};
}

static void add_endpoint(Pixel pixels[MAX_PIXELS], size_t *count,
                         Endpoint endpoint, int steep) {
    const double fractional_y = fraction_part(endpoint.y_end);
    const double complement_fractional_y = reverse_fraction_part(endpoint.y_end);
    add_pixel(pixels, count, endpoint.x_pixel, endpoint.y_pixel,
              complement_fractional_y * endpoint.x_gap, steep);
    add_pixel(pixels, count, endpoint.x_pixel, endpoint.y_pixel + 1,
              fractional_y * endpoint.x_gap, steep);
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t wus_line(const int64_t *values, size_t length,
                 uint8_t *output, size_t output_capacity) {
    if (values == NULL || length != 4) return -1;
    for (size_t index = 0; index < 4; ++index)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;

    int64_t x0 = values[0], y0 = values[1], x1 = values[2], y1 = values[3];
    const int steep = llabs(y1 - y0) > llabs(x1 - x0);
    if (steep) {
        int64_t temporary = x0; x0 = y0; y0 = temporary;
        temporary = x1; x1 = y1; y1 = temporary;
    }
    if (x0 > x1) {
        int64_t temporary = x0; x0 = x1; x1 = temporary;
        temporary = y0; y0 = y1; y1 = temporary;
    }

    const double delta_x = (double)x1 - (double)x0;
    const double delta_y = (double)y1 - (double)y0;
    const double gradient = delta_x == 0.0 ? 1.0 : delta_y / delta_x;
    const Endpoint first = process_endpoint((double)x0, (double)y0, gradient, 1);
    const Endpoint second = process_endpoint((double)x1, (double)y1, gradient, 0);
    Pixel pixels[MAX_PIXELS];
    size_t pixel_count = 0;
    add_endpoint(pixels, &pixel_count, first, steep);
    add_endpoint(pixels, &pixel_count, second, steep);

    double intersection_y = first.y_end + gradient;
    for (int x = first.x_pixel + 1; x < second.x_pixel; ++x) {
        const int y_floor = (int)floor(intersection_y);
        const double fractional = fraction_part(intersection_y);
        const double complement = reverse_fraction_part(intersection_y);
        add_pixel(pixels, &pixel_count, x, y_floor, complement, steep);
        add_pixel(pixels, &pixel_count, x, y_floor + 1, fractional, steep);
        intersection_y += gradient;
    }

    const size_t required = pixel_count * 16;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < pixel_count; ++index) {
        const size_t offset = index * 16;
        write_i32_le(output, offset, pixels[index].x);
        write_i32_le(output, offset + 4, pixels[index].y);
        write_f64_le(output, offset + 8, pixels[index].intensity);
    }
    return (int64_t)required;
}
