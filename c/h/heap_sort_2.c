#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

static void sift_up(int64_t *values, size_t index)
{
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        if (values[parent] >= values[index]) break;
        const int64_t temporary = values[parent];
        values[parent] = values[index];
        values[index] = temporary;
        index = parent;
    }
}

static void sift_down(int64_t *values, size_t size)
{
    size_t root = 0;
    while (root < size / 2) {
        const size_t left = root * 2 + 1;
        size_t largest = left;
        const size_t right = left + 1;
        if (right < size && values[right] > values[left]) largest = right;
        if (values[root] >= values[largest]) break;
        const int64_t temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}

void heap_sort_2(int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return;
    for (size_t index = 0; index < length; ++index) sift_up(values, index);
    for (size_t size = length; size > 1; --size) {
        const int64_t maximum = values[0];
        values[0] = values[size - 1];
        values[size - 1] = maximum;
        sift_down(values, size - 1);
    }
}
