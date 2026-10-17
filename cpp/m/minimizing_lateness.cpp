#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t MAX_JOBS = 64;
constexpr std::size_t MAX_OUTPUT = 4 + 12 * MAX_JOBS;

struct Job {
    std::int32_t processing;
    std::int32_t deadline;
    std::int32_t original_index;
    std::int32_t start_time;
    std::int32_t lateness;
};

void write_i32(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t minimizing_lateness(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 1 + 2 * MAX_JOBS) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MAX_JOBS) ||
        length != 1 + 2 * static_cast<std::size_t>(count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::vector<Job> jobs;
    jobs.reserve(count);
    std::int64_t total_processing = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto processing = input[1 + 2 * i], deadline = input[2 + 2 * i];
        if (processing < 0 || processing > INT32_MAX || deadline < 0 || deadline > INT32_MAX) return -1;
        total_processing += processing;
        if (total_processing > INT32_MAX) return -1;
        jobs.push_back({static_cast<std::int32_t>(processing), static_cast<std::int32_t>(deadline),
                        static_cast<std::int32_t>(i), 0, 0});
    }
    for (std::size_t i = 1; i < count; ++i) {
        const Job item = jobs[i];
        std::size_t position = i;
        while (position > 0 && jobs[position - 1].deadline > item.deadline) {
            jobs[position] = jobs[position - 1];
            --position;
        }
        jobs[position] = item;
    }
    std::int64_t start_time = 0;
    for (auto &job : jobs) {
        job.start_time = static_cast<std::int32_t>(start_time);
        const auto finish_time = start_time + job.processing;
        job.lateness = static_cast<std::int32_t>(finish_time > job.deadline ? finish_time - job.deadline : 0);
        start_time = finish_time;
    }
    std::uint8_t payload[MAX_OUTPUT];
    write_i32(payload, 0, static_cast<std::int32_t>(count));
    for (std::size_t i = 0; i < count; ++i) {
        const auto offset = 4 + 12 * i;
        write_i32(payload, offset, jobs[i].original_index);
        write_i32(payload, offset + 4, jobs[i].start_time);
        write_i32(payload, offset + 8, jobs[i].lateness);
    }
    const auto needed = 4 + 12 * count;
    if (output == nullptr || capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = payload[i];
    return static_cast<std::int64_t>(needed);
}
