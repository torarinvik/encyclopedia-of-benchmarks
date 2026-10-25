// Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
// benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kSide = 16;
constexpr std::size_t kCells = kSide * kSide;
constexpr std::size_t kMaxInput = 3 + kCells;

std::int64_t div_trunc(std::int64_t numerator, std::int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

std::array<std::int64_t, kSide> transform_line(
    const std::array<std::int64_t, kSide>& line, std::size_t n) {
    std::array<std::int64_t, kSide> result{};
    std::array<std::int64_t, kSide / 2> detail{};
    const std::size_t half = n / 2;
    for (std::size_t j = 0; j < half; ++j) {
        const std::int64_t even = line[2 * j];
        const std::int64_t right = (j + 1 < half) ? line[2 * j + 2] : even;
        detail[j] = line[2 * j + 1] - div_trunc(even + right, 2);
    }
    result[0] = line[0] + div_trunc(detail[0] + detail[0] + 2, 4);
    for (std::size_t j = 1; j < half; ++j)
        result[j] = line[2 * j] + div_trunc(detail[j - 1] + detail[j] + 2, 4);
    for (std::size_t j = 0; j < half; ++j) result[half + j] = detail[j];
    return result;
}

void put_i32_le(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    const std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (unsigned byte = 0; byte < 4; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t rodinia_dwt2d(const std::int64_t* values, std::size_t length,
                                       std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 3 || length > kMaxInput) return -1;
    const std::int64_t wi = values[0], hi = values[1], li = values[2];
    if (wi < 2 || wi > static_cast<std::int64_t>(kSide) ||
        hi < 2 || hi > static_cast<std::int64_t>(kSide) || li < 1 || li > 3) return -1;
    const std::int64_t factor = std::int64_t{1} << li;
    if (wi < factor || hi < factor || wi % factor != 0 || hi % factor != 0) return -1;
    const std::size_t width = static_cast<std::size_t>(wi);
    const std::size_t height = static_cast<std::size_t>(hi);
    const std::size_t cells = width * height;
    if (length != 3 + cells) return -1;
    for (std::size_t i = 0; i < cells; ++i)
        if (values[3 + i] < 0 || values[3 + i] > 255) return -1;
    const std::size_t output_bytes = cells * 4;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<std::int64_t, kCells> plane{}, vertical{}, next{}, ordered{};
    std::array<std::int64_t, kSide> line{};
    for (std::size_t i = 0; i < cells; ++i) plane[i] = values[3 + i] - 128;
    std::size_t active_width = width, active_height = height;
    for (std::int64_t level = 0; level < li; ++level) {
        for (std::size_t x = 0; x < active_width; ++x) {
            for (std::size_t y = 0; y < active_height; ++y) line[y] = plane[y * width + x];
            const auto transformed = transform_line(line, active_height);
            for (std::size_t y = 0; y < active_height; ++y) vertical[y * width + x] = transformed[y];
        }
        for (std::size_t y = 0; y < active_height; ++y) {
            for (std::size_t x = 0; x < active_width; ++x) line[x] = vertical[y * width + x];
            const auto transformed = transform_line(line, active_width);
            for (std::size_t x = 0; x < active_width; ++x) next[y * width + x] = transformed[x];
        }
        for (std::size_t y = 0; y < active_height; ++y)
            for (std::size_t x = 0; x < active_width; ++x) plane[y * width + x] = next[y * width + x];
        active_width /= 2;
        active_height /= 2;
    }
    std::size_t output_index = 0;
    for (std::int64_t stage = li - 1; stage >= 0; --stage) {
        const std::size_t stage_width = width >> stage;
        const std::size_t stage_height = height >> stage;
        const std::size_t half_width = stage_width / 2;
        const std::size_t half_height = stage_height / 2;
        if (stage == li - 1)
            for (std::size_t y = 0; y < half_height; ++y)
                for (std::size_t x = 0; x < half_width; ++x)
                    ordered[output_index++] = plane[y * width + x];
        for (std::size_t y = 0; y < half_height; ++y)
            for (std::size_t x = half_width; x < stage_width; ++x)
                ordered[output_index++] = plane[y * width + x];
        for (std::size_t y = half_height; y < stage_height; ++y)
            for (std::size_t x = 0; x < half_width; ++x)
                ordered[output_index++] = plane[y * width + x];
        for (std::size_t y = half_height; y < stage_height; ++y)
            for (std::size_t x = half_width; x < stage_width; ++x)
                ordered[output_index++] = plane[y * width + x];
    }
    for (std::size_t i = 0; i < cells; ++i) put_i32_le(output, 4 * i, ordered[i]);
    return static_cast<std::int64_t>(output_bytes);
}
