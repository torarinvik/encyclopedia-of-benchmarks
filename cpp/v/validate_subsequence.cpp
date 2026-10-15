#include <cstddef>
#include <cstdint>

extern "C" std::int64_t validate_subsequence(const std::int64_t *values,
                                              std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 8194 || values[0] < 0 || values[0] > 4096 ||
        values[1] < 0 || values[1] > 4096) return -1;
    const std::size_t array_length = static_cast<std::size_t>(values[0]);
    const std::size_t sequence_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + array_length + sequence_length) return -1;
    for (std::size_t i = 2; i < length; ++i)
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;

    if (array_length == 0) return 0;
    if (sequence_length == 0) return 1;
    const std::size_t sequence_start = 2 + array_length;
    std::size_t array_index = 0, sequence_index = 0;
    while (sequence_index < sequence_length && array_index < array_length) {
        if (values[sequence_start + sequence_index] == values[2 + array_index]) ++sequence_index;
        ++array_index;
    }
    return sequence_index == sequence_length ? 1 : 0;
}
