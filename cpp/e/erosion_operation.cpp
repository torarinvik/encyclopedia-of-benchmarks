#include <cstddef>
#include <cstdint>

extern "C" int64_t erosion_operation(const int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > 38) return -1;
    const auto height = input[0], width = input[1];
    if (height < 1 || height > 6 || width < 1 || width > 6 ||
        length != 2 + static_cast<std::size_t>(height * width)) return -1;
    for (std::size_t i = 2; i < length; ++i) if (input[i] != 0 && input[i] != 1) return -1;
    int64_t result = 0;
    for (int64_t row = 0; row < height; ++row) for (int64_t col = 0; col < width; ++col) {
        bool keep = input[2 + row * width + col] == 1;
        if (row == 0 || input[2 + (row - 1) * width + col] != 1) keep = false;
        if (row + 1 == height || input[2 + (row + 1) * width + col] != 1) keep = false;
        if (col == 0 || input[2 + row * width + col - 1] != 1) keep = false;
        if (col + 1 == width || input[2 + row * width + col + 1] != 1) keep = false;
        if (keep) result |= int64_t{1} << (row * width + col);
    }
    return result;
}
