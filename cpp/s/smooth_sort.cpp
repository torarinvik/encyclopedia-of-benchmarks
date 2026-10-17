#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 512;
constexpr std::size_t max_parseable_input_length = 514;
constexpr std::int64_t max_value = 1'000'000;
constexpr std::int64_t offset = 1'000'001;
constexpr std::size_t leonardo[16] = {
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973
};

unsigned trailing_zeros(std::uint64_t value)
{
    unsigned count = 0;
    while ((value & 1u) == 0u) {
        value >>= 1u;
        ++count;
    }
    return count;
}

void sift(std::int64_t *values, std::size_t order, std::size_t root)
{
    const std::int64_t value = values[root];
    while (order > 1) {
        const std::size_t right = root - 1;
        const std::size_t left = root - 1 - leonardo[order - 2];
        if (!(value < values[left]) && !(value < values[right])) break;
        if (!(values[left] < values[right])) {
            values[root] = values[left];
            root = left;
            --order;
        } else {
            values[root] = values[right];
            root = right;
            order -= 2;
        }
    }
    values[root] = value;
}

void trinkle(std::int64_t *values, std::uint64_t p, std::size_t order,
             std::size_t root, bool trusty)
{
    const std::int64_t value = values[root];
    while (p != 1) {
        const std::size_t stepson = root - leonardo[order];
        if (!(value < values[stepson])) break;
        if (!trusty && order > 1) {
            const std::size_t right = root - 1;
            const std::size_t left = root - 1 - leonardo[order - 2];
            if (!(values[right] < values[stepson]) || !(values[left] < values[stepson])) break;
        }
        values[root] = values[stepson];
        root = stepson;
        const std::uint64_t mask = p & ~std::uint64_t{1};
        const unsigned shift = trailing_zeros(mask);
        p >>= shift;
        order += shift;
        trusty = false;
    }
    if (!trusty) {
        values[root] = value;
        sift(values, order, root);
    }
}

void smoothsort(std::int64_t *values, std::size_t length)
{
    if (length < 2) return;
    const std::size_t last = length - 1;
    std::uint64_t p = 1;
    std::size_t pshift = 1;
    std::size_t head = 0;
    while (head < last) {
        if ((p & 3u) == 3u) {
            sift(values, pshift, head);
            p >>= 2u;
            pshift += 2;
        } else {
            if (leonardo[pshift - 1] >= last - head) trinkle(values, p, pshift, head, false);
            else sift(values, pshift, head);
            if (pshift == 1) {
                p <<= 1u;
                pshift = 0;
            } else {
                p <<= pshift - 1;
                pshift = 1;
            }
        }
        p |= 1u;
        ++head;
    }
    trinkle(values, p, pshift, head, false);
    while (pshift != 1 || p != 1) {
        if (pshift <= 1) {
            const std::uint64_t mask = p & ~std::uint64_t{1};
            const unsigned shift = trailing_zeros(mask);
            p >>= shift;
            pshift += shift;
        } else {
            p <<= 2u;
            p ^= 7u;
            pshift -= 2;
            trinkle(values, p >> 1u, pshift + 1,
                    head - leonardo[pshift] - 1, true);
            trinkle(values, p, pshift, head - 1, true);
        }
        --head;
    }
}
}

extern "C" std::int64_t smooth_sort_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;

    std::int64_t values[max_n] = {};
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < -max_value || value > max_value) return -1;
        values[index] = value;
    }
    smoothsort(values, count);
    std::int64_t checksum = 0;
    for (std::size_t index = 0; index < count; ++index)
        checksum += static_cast<std::int64_t>(index + 1) * (values[index] + offset);
    return checksum;
}
