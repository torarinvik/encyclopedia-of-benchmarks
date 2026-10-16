/* Bounded port of the pinned Java Xiaolin Wu line rasterizer. */
#include <cmath>
#include <cstdlib>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <utility>

namespace {
constexpr std::int64_t coordinate_limit = 64;
constexpr std::size_t max_pixels = 258;

struct Pixel { std::int32_t x; std::int32_t y; double intensity; };
struct Endpoint { int x_pixel; int y_pixel; double y_end; double x_gap; };

double fraction_part(double value) { return value - std::floor(value); }
double reverse_fraction_part(double value) { return 1.0 - fraction_part(value); }

void add_pixel(Pixel (&pixels)[max_pixels], std::size_t &count,
               int x, int y, double intensity, bool steep) {
    if (steep) { const int temporary = x; x = y; y = temporary; }
    if (intensity < 0.0) intensity = 0.0;
    if (intensity > 1.0) intensity = 1.0;
    pixels[count++] = Pixel{static_cast<std::int32_t>(x), static_cast<std::int32_t>(y), intensity};
}

Endpoint process_endpoint(double x, double y, double gradient, bool is_start) {
    const double x_end = std::floor(x + 0.5);
    const double y_end = y + gradient * (x_end - x);
    const double x_gap = is_start ? reverse_fraction_part(x + 0.5) : fraction_part(x + 0.5);
    return Endpoint{static_cast<int>(x_end), static_cast<int>(std::floor(y_end)), y_end, x_gap};
}

void add_endpoint(Pixel (&pixels)[max_pixels], std::size_t &count,
                  Endpoint endpoint, bool steep) {
    const double fractional_y = fraction_part(endpoint.y_end);
    const double complement = reverse_fraction_part(endpoint.y_end);
    add_pixel(pixels, count, endpoint.x_pixel, endpoint.y_pixel,
              complement * endpoint.x_gap, steep);
    add_pixel(pixels, count, endpoint.x_pixel, endpoint.y_pixel + 1,
              fractional_y * endpoint.x_gap, steep);
}

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

void write_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t wus_line(const std::int64_t *values, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length != 4) return -1;
    for (std::size_t index = 0; index < 4; ++index)
        if (values[index] < -coordinate_limit || values[index] > coordinate_limit) return -1;

    std::int64_t x0 = values[0], y0 = values[1], x1 = values[2], y1 = values[3];
    const bool steep = std::llabs(y1 - y0) > std::llabs(x1 - x0);
    if (steep) { std::swap(x0, y0); std::swap(x1, y1); }
    if (x0 > x1) { std::swap(x0, x1); std::swap(y0, y1); }

    const double delta_x = static_cast<double>(x1) - static_cast<double>(x0);
    const double delta_y = static_cast<double>(y1) - static_cast<double>(y0);
    const double gradient = delta_x == 0.0 ? 1.0 : delta_y / delta_x;
    const Endpoint first = process_endpoint(static_cast<double>(x0), static_cast<double>(y0), gradient, true);
    const Endpoint second = process_endpoint(static_cast<double>(x1), static_cast<double>(y1), gradient, false);
    Pixel pixels[max_pixels];
    std::size_t pixel_count = 0;
    add_endpoint(pixels, pixel_count, first, steep);
    add_endpoint(pixels, pixel_count, second, steep);

    double intersection_y = first.y_end + gradient;
    for (int x = first.x_pixel + 1; x < second.x_pixel; ++x) {
        const int y_floor = static_cast<int>(std::floor(intersection_y));
        const double fractional = fraction_part(intersection_y);
        const double complement = reverse_fraction_part(intersection_y);
        add_pixel(pixels, pixel_count, x, y_floor, complement, steep);
        add_pixel(pixels, pixel_count, x, y_floor + 1, fractional, steep);
        intersection_y += gradient;
    }

    const std::size_t required = pixel_count * 16;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < pixel_count; ++index) {
        const std::size_t offset = index * 16;
        write_i32_le(output, offset, pixels[index].x);
        write_i32_le(output, offset + 4, pixels[index].y);
        write_f64_le(output, offset + 8, pixels[index].intensity);
    }
    return static_cast<std::int64_t>(required);
}
