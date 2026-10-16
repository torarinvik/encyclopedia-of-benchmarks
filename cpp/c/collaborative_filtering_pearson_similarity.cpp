#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_profile_items = 32;
constexpr std::size_t max_input_length = 2 + 4 * max_profile_items;
constexpr std::int64_t max_rating_milli = 1000000000;
constexpr double invalid_result = -2.0;

bool read_profile(const std::int64_t *values, std::size_t start, std::size_t count,
                  std::array<std::int64_t, max_profile_items> &ids,
                  std::array<double, max_profile_items> &ratings)
{
    for (std::size_t index = 0; index < count; ++index) {
        const auto item_id = values[start + 2 * index];
        const auto rating_milli = values[start + 2 * index + 1];
        if (item_id < 0 || item_id > 127 || rating_milli < -max_rating_milli
            || rating_milli > max_rating_milli) return false;
        for (std::size_t earlier = 0; earlier < index; ++earlier)
            if (ids[earlier] == item_id) return false;
        ids[index] = item_id;
        ratings[index] = static_cast<double>(rating_milli) / 1000.0;
    }
    return true;
}
}

extern "C" double collaborative_filtering_pearson_similarity(
    const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > max_input_length) return invalid_result;
    const auto first_count_value = values[0];
    if (first_count_value < 0 || first_count_value > static_cast<std::int64_t>(max_profile_items))
        return invalid_result;
    const auto first_count = static_cast<std::size_t>(first_count_value);
    const auto second_count_position = 1 + 2 * first_count;
    if (second_count_position >= length) return invalid_result;
    const auto second_count_value = values[second_count_position];
    if (second_count_value < 0 || second_count_value > static_cast<std::int64_t>(max_profile_items))
        return invalid_result;
    const auto second_count = static_cast<std::size_t>(second_count_value);
    if (length != second_count_position + 1 + 2 * second_count) return invalid_result;

    std::array<std::int64_t, max_profile_items> first_ids{}, second_ids{};
    std::array<double, max_profile_items> first_ratings{}, second_ratings{};
    if (!read_profile(values, 1, first_count, first_ids, first_ratings)
        || !read_profile(values, second_count_position + 1, second_count, second_ids, second_ratings))
        return invalid_result;

    std::array<double, max_profile_items> common_first{}, common_second{};
    std::size_t common_count = 0;
    for (std::size_t first = 0; first < first_count; ++first) {
        for (std::size_t second = 0; second < second_count; ++second) {
            if (first_ids[first] == second_ids[second]) {
                common_first[common_count] = first_ratings[first];
                common_second[common_count] = second_ratings[second];
                ++common_count;
                break;
            }
        }
    }
    if (common_count == 0) return 0.0;

    double average_first = 0.0, average_second = 0.0;
    for (std::size_t index = 0; index < common_count; ++index) {
        average_first += common_first[index];
        average_second += common_second[index];
    }
    average_first /= static_cast<double>(common_count);
    average_second /= static_cast<double>(common_count);

    double numerator = 0.0, sum_square_first = 0.0, sum_square_second = 0.0;
    for (std::size_t index = 0; index < common_count; ++index) {
        const double difference_first = common_first[index] - average_first;
        const double difference_second = common_second[index] - average_second;
        numerator += difference_first * difference_second;
        sum_square_first += difference_first * difference_first;
        sum_square_second += difference_second * difference_second;
    }
    const double denominator = std::sqrt(sum_square_first * sum_square_second);
    return std::abs(denominator) < 1.0e-10 ? 0.0 : numerator / denominator;
}
