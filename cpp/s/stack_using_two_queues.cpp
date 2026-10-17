#include <cstddef>
#include <cstdint>
#include <climits>

extern "C" std::int64_t stack_using_two_queues(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t output_capacity) {
    if (!input || length < 1 || length > 257 || input[0] < 0 || input[0] > 128 ||
        length != 1 + 2 * static_cast<std::size_t>(input[0])) return -1;
    std::int64_t queue_a[128], queue_b[128], tags[128], results[128];
    std::int64_t *main_q = queue_a, *temp_q = queue_b;
    std::size_t head = 0, tail = 0, record_count = 0, pos = 1;
    for (std::size_t opi = 0; opi < static_cast<std::size_t>(input[0]); ++opi) {
        const auto op = input[pos], value = input[pos + 1]; pos += 2;
        if (op == 0) {
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            std::size_t temp_tail = 0;
            temp_q[temp_tail++] = value;
            while (head < tail) temp_q[temp_tail++] = main_q[head++];
            auto *swap = main_q; main_q = temp_q; temp_q = swap;
            head = 0; tail = temp_tail;
        } else if (op == 1) {
            if (value != 0 || head == tail) return -1;
            tags[record_count] = 0; results[record_count++] = main_q[head++];
        } else if (op == 2) {
            if (value != 0) return -1;
            tags[record_count] = head == tail ? 1 : 0;
            results[record_count++] = head == tail ? 0 : main_q[head];
        } else return -1;
    }
    const std::size_t bytes = record_count * 16;
    if (!output || output_capacity < bytes) return -2;
    for (std::size_t i = 0; i < record_count; ++i) {
        const std::uint64_t words[2] = {static_cast<std::uint64_t>(tags[i]), static_cast<std::uint64_t>(results[i])};
        for (std::size_t w = 0; w < 2; ++w)
            for (std::size_t b = 0; b < 8; ++b) output[16*i+8*w+b] = static_cast<std::uint8_t>(words[w] >> (8*b));
    }
    return static_cast<std::int64_t>(bytes);
}
