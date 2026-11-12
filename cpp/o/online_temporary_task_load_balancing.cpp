#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_machines = 8;
constexpr std::size_t max_tasks = 32;
constexpr std::size_t max_parseable_words = 99;

bool event_less(std::size_t left, std::size_t right,
                const std::array<std::int64_t, max_tasks>& finish) noexcept {
    return finish[left] != finish[right] ? finish[left] < finish[right] : left < right;
}

void heap_push(std::array<std::size_t, max_tasks>& heap, std::size_t& size,
               std::size_t task,
               const std::array<std::int64_t, max_tasks>& finish) noexcept {
    auto position = size++;
    while (position > 0) {
        const auto parent = (position - 1) / 2;
        if (!event_less(task, heap[parent], finish)) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = task;
}

std::size_t heap_pop(std::array<std::size_t, max_tasks>& heap, std::size_t& size,
                     const std::array<std::int64_t, max_tasks>& finish) noexcept {
    const auto minimum = heap[0];
    --size;
    if (size == 0) return minimum;
    const auto replacement = heap[size];
    std::size_t position = 0;
    for (;;) {
        const auto left = 2 * position + 1;
        if (left >= size) break;
        const auto right = left + 1;
        auto child = left;
        if (right < size && event_less(heap[right], heap[left], finish)) child = right;
        if (!event_less(heap[child], replacement, finish)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = replacement;
    return minimum;
}
}

extern "C" std::int64_t online_temporary_task_load_balancing(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_words) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_machines) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_tasks)) return -1;
    const auto machine_count = static_cast<std::size_t>(input[0]);
    const auto task_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3 * task_count) return -1;

    std::array<std::int64_t, max_tasks> arrival{};
    std::array<std::int64_t, max_tasks> weight{};
    std::array<std::int64_t, max_tasks> finish{};
    std::array<std::size_t, max_tasks> assigned{};
    std::array<std::int64_t, max_machines> loads{};
    std::array<std::size_t, max_tasks> heap{};
    std::size_t heap_size = 0;
    std::array<std::int64_t, max_tasks + 1> staged{};
    std::int64_t previous_arrival = -1;

    for (std::size_t task = 0; task < task_count; ++task) {
        const auto at = input[2 + 3 * task];
        const auto amount = input[3 + 3 * task];
        const auto duration = input[4 + 3 * task];
        if (at < 0 || at > 1000 || at < previous_arrival ||
            amount < 1 || amount > 1000 || duration < 1 || duration > 1000 ||
            at + duration > 2000) return -1;
        arrival[task] = at;
        weight[task] = amount;
        finish[task] = at + duration;
        previous_arrival = at;
    }

    std::int64_t peak = 0;
    for (std::size_t task = 0; task < task_count; ++task) {
        while (heap_size > 0 && finish[heap[0]] <= arrival[task]) {
            const auto expired = heap_pop(heap, heap_size, finish);
            loads[assigned[expired]] -= weight[expired];
        }
        std::size_t machine = 0;
        for (std::size_t candidate = 1; candidate < machine_count; ++candidate)
            if (loads[candidate] < loads[machine]) machine = candidate;
        assigned[task] = machine;
        loads[machine] += weight[task];
        if (loads[machine] > peak) peak = loads[machine];
        heap_push(heap, heap_size, task, finish);
    }

    staged[0] = peak;
    for (std::size_t task = 0; task < task_count; ++task) staged[task + 1] = static_cast<std::int64_t>(assigned[task]);
    const auto output_words = task_count + 1;
    const auto output_bytes = 8 * output_words;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t word = 0; word < output_words; ++word)
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[8 * word + byte] = static_cast<std::uint8_t>((static_cast<std::uint64_t>(staged[word]) >> (8 * byte)) & 255u);
    return static_cast<std::int64_t>(output_bytes);
}
