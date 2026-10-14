#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;

void sift_up(std::int64_t *values, std::size_t index)
{
    while (index > 0) {
        const std::size_t parent = (index - 1) / 2;
        if (values[parent] >= values[index]) break;
        const std::int64_t temporary = values[parent];
        values[parent] = values[index];
        values[index] = temporary;
        index = parent;
    }
}

void sift_down(std::int64_t *values, std::size_t size)
{
    std::size_t root = 0;
    while (root < size / 2) {
        const std::size_t left = root * 2 + 1;
        std::size_t largest = left;
        const std::size_t right = left + 1;
        if (right < size && values[right] > values[left]) largest = right;
        if (values[root] >= values[largest]) break;
        const std::int64_t temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}
}

extern "C" void heap_sort_2(std::int64_t *values, std::size_t length)
{
    if (length > max_values) return;
    for (std::size_t index = 0; index < length; ++index) sift_up(values, index);
    for (std::size_t size = length; size > 1; --size) {
        const std::int64_t maximum = values[0];
        values[0] = values[size - 1];
        values[size - 1] = maximum;
        sift_down(values, size - 1);
    }
}
