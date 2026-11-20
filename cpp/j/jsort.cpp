#include <cstddef>
#include <cstdint>

namespace {
void sift_down_min(std::int64_t* values, std::size_t root, std::size_t end) noexcept {
    while (root < end / 2) {
        auto child = root * 2 + 1;
        if (child + 1 < end && values[child + 1] < values[child]) ++child;
        if (values[root] <= values[child]) break;
        const auto temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

void sift_down_max(std::int64_t* values, std::size_t root, std::size_t end) noexcept {
    while (root < end / 2) {
        auto child = root * 2 + 1;
        if (child + 1 < end && values[child + 1] > values[child]) ++child;
        if (values[root] >= values[child]) break;
        const auto temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

void reverse_values(std::int64_t* values, std::size_t length) noexcept {
    for (std::size_t left = 0; left < length / 2; ++left) {
        const std::size_t right = length - 1 - left;
        const auto temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}
}

extern "C" void jsort(std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return;
    for (std::size_t start = length / 2; start > 0;) {
        --start;
        sift_down_min(values, start, length);
    }
    reverse_values(values, length);
    for (std::size_t start = length / 2; start > 0;) {
        --start;
        sift_down_max(values, start, length);
    }
    reverse_values(values, length);

    for (std::size_t index = 1; index < length; ++index) {
        const auto key = values[index];
        auto position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = key;
    }
}
