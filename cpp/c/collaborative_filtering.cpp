#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_users = 65;
constexpr std::size_t max_input_length = 1 + 4 * max_users;
constexpr std::int64_t max_similarity_ticks = INT64_C(1000000000000);
constexpr std::int64_t max_rating_milli = INT64_C(1000000000);
constexpr double invalid_result = -1.0e300;
}

extern "C" double collaborative_filtering(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 1 || length > max_input_length) return invalid_result;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_users)) return invalid_result;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 4 * count) return invalid_result;

    double total_similarity = 0.0;
    double weighted_sum = 0.0;
    std::size_t target_user_count = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto offset = 1 + 4 * index;
        const auto is_target_user = values[offset];
        const auto has_target_rating = values[offset + 1];
        const auto similarity_ticks = values[offset + 2];
        const auto rating_milli = values[offset + 3];
        if ((is_target_user != 0 && is_target_user != 1)
            || (has_target_rating != 0 && has_target_rating != 1)
            || similarity_ticks < -max_similarity_ticks || similarity_ticks > max_similarity_ticks
            || rating_milli < -max_rating_milli || rating_milli > max_rating_milli)
            return invalid_result;
        if (is_target_user == 1) {
            ++target_user_count;
            continue;
        }
        if (has_target_rating == 0) continue;
        const double similarity = static_cast<double>(similarity_ticks) / 1.0e12;
        const double rating = static_cast<double>(rating_milli) / 1000.0;
        total_similarity += std::abs(similarity);
        weighted_sum += similarity * rating;
    }
    if (target_user_count != 1) return invalid_result;
    return std::abs(total_similarity) < 1.0e-10 ? 0.0 : weighted_sum / total_similarity;
}
