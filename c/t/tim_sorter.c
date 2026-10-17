#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 512u
#define MAX_PARSEABLE_INPUT_VALUES 1026u
#define MIN_MERGE 32u
#define MODULUS INT64_C(1000000007)
#define CHECKSUM_MULTIPLIER INT64_C(1000003)

typedef struct {
    int64_t key;
    int64_t item_id;
} Item;

static void reverse_range(Item *items, size_t start, size_t end)
{
    while (start < end) {
        --end;
        if (start >= end) break;
        const Item temporary = items[start];
        items[start++] = items[end];
        items[end] = temporary;
    }
}

static size_t count_run_and_make_ascending(Item *items, size_t start, size_t count)
{
    size_t run_hi = start + 1u;
    if (run_hi == count) return 1u;
    if (items[run_hi].key < items[start].key) {
        ++run_hi;
        while (run_hi < count && items[run_hi].key < items[run_hi - 1u].key) ++run_hi;
        reverse_range(items, start, run_hi);
    } else {
        ++run_hi;
        while (run_hi < count && items[run_hi].key >= items[run_hi - 1u].key) ++run_hi;
    }
    return run_hi - start;
}

static void binary_sort(Item *items, size_t start, size_t end, size_t first)
{
    if (first >= end || first <= start) first = start + 1u;
    for (; first < end; ++first) {
        const Item target = items[first];
        size_t left = start;
        size_t right = first;
        while (left < right) {
            const size_t middle = (left + right) / 2u;
            if (target.key < items[middle].key) right = middle;
            else left = middle + 1u;
        }
        for (size_t index = first; index > left; --index) items[index] = items[index - 1u];
        items[left] = target;
    }
}

static size_t min_run_length(size_t total)
{
    size_t remainder = 0u;
    while (total >= MIN_MERGE) {
        remainder |= total & 1u;
        total >>= 1u;
    }
    return total + remainder;
}

static void merge_at(Item *items, size_t *run_base, size_t *run_lengths,
                     size_t *stack_size, size_t index)
{
    const size_t base_a = run_base[index];
    const size_t len_a = run_lengths[index];
    const size_t base_b = run_base[index + 1u];
    const size_t len_b = run_lengths[index + 1u];
    run_lengths[index] = len_a + len_b;
    if (index == *stack_size - 3u) {
        run_base[index + 1u] = run_base[index + 2u];
        run_lengths[index + 1u] = run_lengths[index + 2u];
    }
    --*stack_size;

    Item temporary[MAX_ITEMS];
    for (size_t offset = 0u; offset < len_a; ++offset) temporary[offset] = items[base_a + offset];
    size_t left = 0u;
    size_t right = base_b;
    size_t destination = base_a;
    const size_t right_end = base_b + len_b;
    while (left < len_a && right < right_end) {
        if (temporary[left].key <= items[right].key) items[destination++] = temporary[left++];
        else items[destination++] = items[right++];
    }
    while (left < len_a) items[destination++] = temporary[left++];
}

static void merge_collapse(Item *items, size_t *run_base, size_t *run_lengths, size_t *stack_size)
{
    while (*stack_size > 1u) {
        size_t index = *stack_size - 2u;
        if (index > 0u && run_lengths[index - 1u] <= run_lengths[index] + run_lengths[index + 1u]) {
            if (run_lengths[index - 1u] < run_lengths[index + 1u]) --index;
            merge_at(items, run_base, run_lengths, stack_size, index);
        } else if (run_lengths[index] <= run_lengths[index + 1u]) {
            merge_at(items, run_base, run_lengths, stack_size, index);
        } else {
            break;
        }
    }
}

static void merge_force_collapse(Item *items, size_t *run_base, size_t *run_lengths, size_t *stack_size)
{
    while (*stack_size > 1u) {
        size_t index = *stack_size - 2u;
        if (index > 0u && run_lengths[index - 1u] < run_lengths[index + 1u]) --index;
        merge_at(items, run_base, run_lengths, stack_size, index);
    }
}

static void tim_sort(Item *items, size_t count)
{
    if (count < MIN_MERGE) {
        if (count > 1u) binary_sort(items, 0u, count, 0u);
        return;
    }

    size_t run_base[MAX_ITEMS];
    size_t run_lengths[MAX_ITEMS];
    size_t stack_size = 0u;
    const size_t min_run = min_run_length(count);
    size_t start = 0u;
    size_t remaining = count;
    do {
        size_t run_length = count_run_and_make_ascending(items, start, count);
        if (run_length < min_run) {
            const size_t force = min_run < remaining ? min_run : remaining;
            binary_sort(items, start, start + force, start + run_length);
            run_length = force;
        }
        run_base[stack_size] = start;
        run_lengths[stack_size] = run_length;
        ++stack_size;
        merge_collapse(items, run_base, run_lengths, &stack_size);
        start += run_length;
        remaining -= run_length;
    } while (remaining != 0u);
    merge_force_collapse(items, run_base, run_lengths, &stack_size);
}

int64_t tim_sorter_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_ITEMS) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1u + 2u * count) return -1;

    Item items[MAX_ITEMS];
    int seen[MAX_ITEMS] = {0};
    for (size_t index = 0u; index < count; ++index) {
        const int64_t key = input[1u + 2u * index];
        const int64_t item_id = input[2u + 2u * index];
        if (key < -1000 || key > 1000 || item_id < 0 || item_id >= (int64_t)count) return -1;
        if (seen[(size_t)item_id]) return -1;
        seen[(size_t)item_id] = 1;
        items[index] = (Item){key, item_id};
    }

    tim_sort(items, count);
    int64_t checksum = 0;
    for (size_t index = 0u; index < count; ++index) {
        const int64_t token = (items[index].key + 1000) * 513 + items[index].item_id + 1;
        checksum = (checksum * CHECKSUM_MULTIPLIER + token) % MODULUS;
    }
    return checksum;
}
