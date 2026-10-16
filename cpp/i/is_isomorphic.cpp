/* Check whether two bounded ASCII strings preserve a one-to-one mapping. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t is_isomorphic(const std::int64_t *input,
                                      std::size_t length) noexcept {
    constexpr std::size_t kMaxCodepoints = 8;
    constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxCodepoints + 2;
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto source_length = input[0];
    const auto target_length = input[1];
    if (source_length < 0 || source_length > static_cast<std::int64_t>(kMaxCodepoints) ||
        target_length < 0 || target_length > static_cast<std::int64_t>(kMaxCodepoints)) return -1;
    const auto source_count = static_cast<std::size_t>(source_length);
    const auto target_count = static_cast<std::size_t>(target_length);
    if (length != 2 + source_count + target_count) return -1;

    for (std::size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (source_count != target_count) return 0;

    std::int64_t source_to_target[128], target_to_source[128];
    for (std::size_t index = 0; index < 128; ++index) {
        source_to_target[index] = -1;
        target_to_source[index] = -1;
    }
    for (std::size_t index = 0; index < source_count; ++index) {
        const auto source = input[2 + index];
        const auto target = input[2 + source_count + index];
        if ((source_to_target[source] != -1 && source_to_target[source] != target) ||
            (target_to_source[target] != -1 && target_to_source[target] != source)) return 0;
        source_to_target[source] = target;
        target_to_source[target] = source;
    }
    return 1;
}
