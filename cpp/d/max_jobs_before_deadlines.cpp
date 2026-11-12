#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_jobs = 12;

struct Job {
    std::int64_t deadline;
    std::int64_t duration;
    int id;
};

struct MinHeap {
    std::array<std::int64_t, max_jobs> durations{};
    std::array<int, max_jobs> ids{};
    std::size_t size = 0;

    static bool before(std::int64_t left_duration, int left_id,
                       std::int64_t right_duration, int right_id) noexcept {
        return left_duration < right_duration ||
               (left_duration == right_duration && left_id < right_id);
    }

    void push(std::int64_t duration, int id) noexcept {
        auto index = size++;
        while (index > 0) {
            const auto parent = (index - 1) / 2;
            if (!before(duration, id, durations[parent], ids[parent])) break;
            durations[index] = durations[parent];
            ids[index] = ids[parent];
            index = parent;
        }
        durations[index] = duration;
        ids[index] = id;
    }

    void pop(std::int64_t &duration, int &id) noexcept {
        duration = durations[0];
        id = ids[0];
        --size;
        if (size == 0) return;
        const auto last_duration = durations[size];
        const int last_id = ids[size];
        std::size_t index = 0;
        while (2 * index + 1 < size) {
            auto child = 2 * index + 1;
            if (child + 1 < size && before(durations[child + 1], ids[child + 1],
                                           durations[child], ids[child])) ++child;
            if (!before(durations[child], ids[child], last_duration, last_id)) break;
            durations[index] = durations[child];
            ids[index] = ids[child];
            index = child;
        }
        durations[index] = last_duration;
        ids[index] = last_id;
    }
};
}

extern "C" std::int64_t max_jobs_before_deadlines(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 1 + 2 * max_jobs) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_jobs) ||
        length != 1 + 2 * static_cast<std::size_t>(count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::array<Job, max_jobs> jobs{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto deadline = input[1 + 2 * i];
        const auto duration = input[2 + 2 * i];
        if (deadline < 0 || deadline > 1000 || duration < 1 || duration > 1000) return -1;
        jobs[i] = {deadline, duration, static_cast<int>(i)};
    }
    for (std::size_t i = 1; i < count; ++i) {
        const auto item = jobs[i];
        auto position = i;
        while (position > 0 && jobs[position - 1].deadline > item.deadline) {
            jobs[position] = jobs[position - 1];
            --position;
        }
        jobs[position] = item;
    }
    MinHeap heap;
    std::int64_t completed = 0;
    for (std::size_t end = count; end > 0; --end) {
        const auto index = end - 1;
        heap.push(jobs[index].duration, jobs[index].id);
        const auto lower = index == 0 ? 0 : jobs[index - 1].deadline;
        auto interval = jobs[index].deadline - lower;
        while (interval > 0 && heap.size > 0) {
            std::int64_t remaining;
            int id;
            heap.pop(remaining, id);
            if (remaining <= interval) {
                interval -= remaining;
                ++completed;
            } else {
                heap.push(remaining - interval, id);
                interval = 0;
            }
        }
    }
    return completed;
}
