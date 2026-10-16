#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -9223372036854775807LL - 1;
constexpr std::int64_t int32_min_value = -2147483648LL;
constexpr std::int64_t int32_max_value = 2147483647LL;
constexpr std::size_t max_input_length = 259;
}

extern "C" std::int64_t second_min_max(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return invalid_result;
    const auto operation = input[0], raw_count = input[1];
    if ((operation != 0 && operation != 1) || raw_count < 2 || raw_count > 256) return invalid_result;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != count + 2) return invalid_result;
    const auto initial = operation == 0 ? int32_max_value : int32_min_value;
    auto best = initial, second = initial;
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 2];
        if (value < int32_min_value || value > int32_max_value) return invalid_result;
        const bool better = operation == 0 ? value < best : value > best;
        if (better) {
            second = best;
            best = value;
        } else {
            const bool improves_second = operation == 0 ? value < second : value > second;
            if (improves_second && value != best) second = value;
        }
    }
    return second == initial ? invalid_result : second;
}
