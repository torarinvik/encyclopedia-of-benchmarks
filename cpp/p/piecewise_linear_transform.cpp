#include <cstddef>
#include <cstdint>

extern "C" std::int64_t piecewise_linear_transform(const std::int64_t *input,
                                                    std::size_t length,
                                                    std::uint8_t *output,
                                                    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 256) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 255) return -1;
    if (output == nullptr || capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const double pixel = static_cast<double>(input[index]);
        const double mapped = pixel <= 100.0 ? (50.0 / 100.0) * pixel :
            pixel <= 180.0 ? ((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0 :
            ((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0;
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(length);
}
