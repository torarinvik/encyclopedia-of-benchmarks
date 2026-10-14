#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;
constexpr std::size_t max_pairs = max_values / 2;

void sort_pairs(std::int64_t *low, std::int64_t *high,
                std::int64_t *scratch_low, std::int64_t *scratch_high,
                std::size_t count)
{
    for (std::size_t width = 1; width < count; width *= 2) {
        for (std::size_t start = 0; start < count; start += width * 2) {
            std::size_t middle = start + width;
            if (middle > count) middle = count;
            std::size_t end = middle + width;
            if (end > count) end = count;
            std::size_t left = start;
            std::size_t right = middle;
            std::size_t output = start;
            while (left < middle && right < end) {
                const std::size_t source = low[left] <= low[right] ? left++ : right++;
                scratch_low[output] = low[source];
                scratch_high[output++] = high[source];
            }
            while (left < middle) { scratch_low[output] = low[left]; scratch_high[output++] = high[left++]; }
            while (right < end) { scratch_low[output] = low[right]; scratch_high[output++] = high[right++]; }
            for (std::size_t index = start; index < end; ++index) {
                low[index] = scratch_low[index];
                high[index] = scratch_high[index];
            }
        }
        if (width > count / 2) break;
    }
}

void binary_insert(std::int64_t *values, std::size_t &length, std::int64_t item)
{
    std::size_t low = 0;
    std::size_t high = length;
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        if (values[middle] < item) low = middle + 1;
        else high = middle;
    }
    for (std::size_t index = length; index > low; --index) values[index] = values[index - 1];
    values[low] = item;
    ++length;
}
}

extern "C" void merge_insertion_sort(std::int64_t *values, std::size_t length)
{
    if (length > max_values) return;
    std::int64_t pair_low[max_pairs];
    std::int64_t pair_high[max_pairs];
    std::int64_t scratch_low[max_pairs];
    std::int64_t scratch_high[max_pairs];
    std::int64_t chain[max_values];
    const std::size_t pair_count = length / 2;
    for (std::size_t pair = 0; pair < pair_count; ++pair) {
        const std::int64_t first = values[pair * 2];
        const std::int64_t second = values[pair * 2 + 1];
        if (first <= second) { pair_low[pair] = first; pair_high[pair] = second; }
        else { pair_low[pair] = second; pair_high[pair] = first; }
    }
    sort_pairs(pair_low, pair_high, scratch_low, scratch_high, pair_count);
    std::size_t chain_length = 0;
    for (std::size_t pair = 0; pair < pair_count; ++pair) chain[chain_length++] = pair_low[pair];
    if (pair_count > 0) chain[chain_length++] = pair_high[pair_count - 1];
    if (length % 2 != 0) binary_insert(chain, chain_length, values[length - 1]);
    for (std::size_t pair = 0; pair + 1 < pair_count; ++pair) binary_insert(chain, chain_length, pair_high[pair]);
    for (std::size_t index = 0; index < length; ++index) values[index] = chain[index];
}
