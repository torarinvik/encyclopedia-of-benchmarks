#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_queues = 4;
constexpr std::size_t max_processes = 8;
constexpr std::size_t max_input_words = 13;
constexpr std::size_t max_output_words = 1 + 4 * max_processes;
constexpr std::size_t max_output_bytes = 4 * max_output_words;
struct Process { std::int32_t id, remaining, waiting, turnaround, stop_time; };

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t multi_level_feedback_queue(const std::int32_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_words) return -1;
    const auto queue_count = input[0], process_count = input[1];
    if (queue_count < 1 || queue_count > static_cast<std::int32_t>(max_queues) ||
        process_count < 0 || process_count > static_cast<std::int32_t>(max_processes) ||
        length != 2 + static_cast<std::size_t>(queue_count - 1) + static_cast<std::size_t>(process_count)) return -1;

    std::int32_t slices[max_queues - 1] = {};
    std::size_t pos = 2;
    for (std::int32_t i = 0; i < queue_count - 1; ++i) {
        if (input[pos] < 1 || input[pos] > 16) return -1;
        slices[i] = input[pos++];
    }
    Process ready[max_processes] = {};
    std::size_t ready_count = static_cast<std::size_t>(process_count);
    for (std::int32_t i = 0; i < process_count; ++i) {
        const auto burst = input[pos++];
        if (burst < 1 || burst > 16) return -1;
        ready[i] = {i, burst, 0, 0, 0};
    }

    Process finished[max_processes] = {};
    std::size_t finished_count = 0;
    std::int32_t current_time = 0;
    for (std::int32_t level = 0; level < queue_count - 1; ++level) {
        Process next_ready[max_processes] = {};
        std::size_t next_count = 0;
        const auto time_slice = slices[level];
        for (std::size_t i = 0; i < ready_count; ++i) {
            auto process = ready[i];
            process.waiting += current_time - process.stop_time;
            if (process.remaining > time_slice) {
                current_time += time_slice;
                process.remaining -= time_slice;
                process.stop_time = current_time;
                next_ready[next_count++] = process;
            } else {
                current_time += process.remaining;
                process.remaining = 0;
                process.stop_time = current_time;
                process.turnaround = current_time;
                finished[finished_count++] = process;
            }
        }
        ready_count = next_count;
        for (std::size_t i = 0; i < next_count; ++i) ready[i] = next_ready[i];
    }
    for (std::size_t i = 0; i < ready_count; ++i) {
        auto process = ready[i];
        process.waiting += current_time - process.stop_time;
        current_time += process.remaining;
        process.remaining = 0;
        process.stop_time = current_time;
        process.turnaround = current_time;
        finished[finished_count++] = process;
    }

    if (finished_count != static_cast<std::size_t>(process_count)) return -1;
    std::int32_t words[max_output_words] = {};
    std::size_t word_count = 1;
    words[0] = process_count;
    for (std::size_t i = 0; i < finished_count; ++i) {
        words[word_count++] = finished[i].id;
        words[word_count++] = finished[i].waiting;
        words[word_count++] = finished[i].turnaround;
        words[word_count++] = finished[i].stop_time;
    }
    const auto bytes = word_count * 4;
    if (bytes > max_output_bytes || output == nullptr || capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    for (std::size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
