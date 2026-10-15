#include <cstddef>
#include <cstdint>

static void sift_down(std::int64_t *values, std::size_t root, std::size_t end)
{
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const std::int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

extern "C" std::int64_t maximum_bags_with_full_capacity(const std::int64_t *input,
                                                          std::size_t length)
{
    if (input == nullptr || length < 2 || length > 16384) return -1;
    std::int64_t remaining = input[0];
    if (remaining < 0 || remaining > 1000000000) return -1;
    if (input[1] < 0 || input[1] > 8191) return -1;
    const std::size_t count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * count) return -1;
    std::int64_t deficits[8191];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t capacity = input[2 + index];
        const std::int64_t rocks = input[2 + count + index];
        if (capacity < 1 || capacity > 100000 || rocks < 0 || rocks > capacity) return -1;
        deficits[index] = capacity - rocks;
    }
    for (std::size_t start = count / 2; start > 0;) {
        --start;
        sift_down(deficits, start, count);
    }
    for (std::size_t end = count; end > 1;) {
        --end;
        const std::int64_t temporary = deficits[0];
        deficits[0] = deficits[end];
        deficits[end] = temporary;
        sift_down(deficits, 0, end);
    }
    std::int64_t full_bags = 0;
    for (std::size_t index = 0; index < count; ++index) {
        if (deficits[index] > remaining) break;
        remaining -= deficits[index];
        ++full_bags;
    }
    return full_bags;
}
