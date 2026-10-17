#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 512;
constexpr std::size_t max_parseable_input_length = 1026;
constexpr std::size_t min_merge = 32;
constexpr std::int64_t hash_multiplier = 1000003;
constexpr std::int64_t hash_modulus = 1000000007;

struct Item {
    std::int64_t key;
    std::int64_t item_id;
};

void reverse_range(Item *items, std::size_t start, std::size_t end)
{
    while (start < end) {
        --end;
        if (start >= end) break;
        const Item temporary = items[start];
        items[start++] = items[end];
        items[end] = temporary;
    }
}

std::size_t count_run_and_make_ascending(Item *items, std::size_t start, std::size_t count)
{
    std::size_t run_hi = start + 1;
    if (run_hi == count) return 1;
    if (items[run_hi].key < items[start].key) {
        ++run_hi;
        while (run_hi < count && items[run_hi].key < items[run_hi - 1].key) ++run_hi;
        reverse_range(items, start, run_hi);
    } else {
        ++run_hi;
        while (run_hi < count && items[run_hi].key >= items[run_hi - 1].key) ++run_hi;
    }
    return run_hi - start;
}

void binary_sort(Item *items, std::size_t start, std::size_t end, std::size_t first)
{
    if (first >= end || first <= start) first = start + 1;
    for (; first < end; ++first) {
        const Item target = items[first];
        std::size_t left = start;
        std::size_t right = first;
        while (left < right) {
            const std::size_t middle = (left + right) / 2;
            if (target.key < items[middle].key) right = middle;
            else left = middle + 1;
        }
        for (std::size_t index = first; index > left; --index) items[index] = items[index - 1];
        items[left] = target;
    }
}

std::size_t min_run_length(std::size_t total)
{
    std::size_t remainder = 0;
    while (total >= min_merge) {
        remainder |= total & 1;
        total >>= 1;
    }
    return total + remainder;
}

void merge_at(Item *items, std::size_t *run_base, std::size_t *run_lengths,
              std::size_t *stack_size, std::size_t index)
{
    const std::size_t base_a = run_base[index];
    const std::size_t len_a = run_lengths[index];
    const std::size_t base_b = run_base[index + 1];
    const std::size_t len_b = run_lengths[index + 1];
    run_lengths[index] = len_a + len_b;
    if (index == *stack_size - 3) {
        run_base[index + 1] = run_base[index + 2];
        run_lengths[index + 1] = run_lengths[index + 2];
    }
    --*stack_size;

    Item temporary[max_items];
    for (std::size_t offset = 0; offset < len_a; ++offset) temporary[offset] = items[base_a + offset];
    std::size_t left = 0;
    std::size_t right = base_b;
    std::size_t destination = base_a;
    const std::size_t right_end = base_b + len_b;
    while (left < len_a && right < right_end) {
        if (temporary[left].key <= items[right].key) items[destination++] = temporary[left++];
        else items[destination++] = items[right++];
    }
    while (left < len_a) items[destination++] = temporary[left++];
}

void merge_collapse(Item *items, std::size_t *run_base, std::size_t *run_lengths,
                    std::size_t *stack_size)
{
    while (*stack_size > 1) {
        std::size_t index = *stack_size - 2;
        if (index > 0 && run_lengths[index - 1] <= run_lengths[index] + run_lengths[index + 1]) {
            if (run_lengths[index - 1] < run_lengths[index + 1]) --index;
            merge_at(items, run_base, run_lengths, stack_size, index);
        } else if (run_lengths[index] <= run_lengths[index + 1]) {
            merge_at(items, run_base, run_lengths, stack_size, index);
        } else {
            break;
        }
    }
}

void merge_force_collapse(Item *items, std::size_t *run_base, std::size_t *run_lengths,
                          std::size_t *stack_size)
{
    while (*stack_size > 1) {
        std::size_t index = *stack_size - 2;
        if (index > 0 && run_lengths[index - 1] < run_lengths[index + 1]) --index;
        merge_at(items, run_base, run_lengths, stack_size, index);
    }
}

void tim_sort(Item *items, std::size_t count)
{
    if (count < min_merge) {
        if (count > 1) binary_sort(items, 0, count, 0);
        return;
    }

    std::size_t run_base[max_items];
    std::size_t run_lengths[max_items];
    std::size_t stack_size = 0;
    const std::size_t min_run = min_run_length(count);
    std::size_t start = 0;
    std::size_t remaining = count;
    do {
        std::size_t run_length = count_run_and_make_ascending(items, start, count);
        if (run_length < min_run) {
            const std::size_t force = min_run < remaining ? min_run : remaining;
            binary_sort(items, start, start + force, start + run_length);
            run_length = force;
        }
        run_base[stack_size] = start;
        run_lengths[stack_size] = run_length;
        ++stack_size;
        merge_collapse(items, run_base, run_lengths, &stack_size);
        start += run_length;
        remaining -= run_length;
    } while (remaining != 0);
    merge_force_collapse(items, run_base, run_lengths, &stack_size);
}
} // namespace

extern "C" std::int64_t tim_sorter_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_items)) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return -1;

    Item items[max_items];
    bool seen[max_items] = {};
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t key = input[1 + 2 * index];
        const std::int64_t item_id = input[2 + 2 * index];
        if (key < -1000 || key > 1000 || item_id < 0 || item_id >= static_cast<std::int64_t>(count)) return -1;
        if (seen[static_cast<std::size_t>(item_id)]) return -1;
        seen[static_cast<std::size_t>(item_id)] = true;
        items[index] = Item{key, item_id};
    }

    tim_sort(items, count);
    std::int64_t checksum = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t token = (items[index].key + 1000) * 513 + items[index].item_id + 1;
        checksum = (checksum * hash_multiplier + token) % hash_modulus;
    }
    return checksum;
}
