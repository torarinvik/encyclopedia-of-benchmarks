#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 32;
constexpr std::size_t max_dimension = 4;
constexpr std::size_t max_centers = 8;
constexpr std::size_t max_input_length = 140;

std::int64_t squared_distance(const std::int64_t* coordinates,
                              std::size_t dimension,
                              std::size_t row,
                              std::size_t center) {
    std::int64_t distance = 0;
    for (std::size_t axis = 0; axis < dimension; ++axis) {
        const auto difference = coordinates[row * dimension + axis]
                              - coordinates[center * dimension + axis];
        distance += difference * difference;
    }
    return distance;
}

bool row_is_selected(const std::int64_t* centers, std::size_t count,
                     std::int64_t row) {
    for (std::size_t index = 0; index < count; ++index)
        if (centers[index] == row) return true;
    return false;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t kmeans_plus_plus_seeding(const std::int64_t* input,
                                                   std::size_t length,
                                                   std::uint8_t* output,
                                                   std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const auto point_count_value = input[0];
    const auto dimension_value = input[1];
    const auto center_count_value = input[2];
    const auto first_row = input[3];
    if (point_count_value < 1 || point_count_value > static_cast<std::int64_t>(max_points)
        || dimension_value < 1 || dimension_value > static_cast<std::int64_t>(max_dimension)
        || center_count_value < 1 || center_count_value > static_cast<std::int64_t>(max_centers)
        || center_count_value > point_count_value || first_row < 0 || first_row >= point_count_value)
        return -1;

    const auto point_count = static_cast<std::size_t>(point_count_value);
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const auto center_count = static_cast<std::size_t>(center_count_value);
    const auto coordinate_count = point_count * dimension;
    const auto draw_offset = 4 + coordinate_count;
    if (length != draw_offset + center_count - 1) return -1;

    std::int64_t coordinates[max_points * max_dimension]{};
    for (std::size_t index = 0; index < coordinate_count; ++index) {
        const auto coordinate = input[4 + index];
        if (coordinate < -16 || coordinate > 16) return -1;
        coordinates[index] = coordinate;
    }

    std::int64_t centers[max_centers]{};
    std::int64_t nearest[max_points]{};
    centers[0] = first_row;
    for (std::size_t row = 0; row < point_count; ++row)
        nearest[row] = squared_distance(coordinates, dimension, row,
                                        static_cast<std::size_t>(first_row));

    for (std::size_t step = 0; step + 1 < center_count; ++step) {
        const auto draw = input[draw_offset + step];
        std::int64_t total_weight = 0;
        for (std::size_t row = 0; row < point_count; ++row) total_weight += nearest[row];

        std::int64_t chosen = -1;
        if (total_weight == 0) {
            if (draw != 0) return -1;
            for (std::size_t row = 0; row < point_count; ++row) {
                if (!row_is_selected(centers, step + 1, static_cast<std::int64_t>(row))) {
                    chosen = static_cast<std::int64_t>(row);
                    break;
                }
            }
        } else {
            if (draw < 0 || draw >= total_weight) return -1;
            std::int64_t cumulative = 0;
            for (std::size_t row = 0; row < point_count; ++row) {
                cumulative += nearest[row];
                if (cumulative > draw) {
                    chosen = static_cast<std::int64_t>(row);
                    break;
                }
            }
        }
        if (chosen < 0) return -1;
        centers[step + 1] = chosen;
        for (std::size_t row = 0; row < point_count; ++row) {
            const auto distance = squared_distance(coordinates, dimension, row,
                                                   static_cast<std::size_t>(chosen));
            if (distance < nearest[row]) nearest[row] = distance;
        }
    }

    const auto output_bytes = center_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < center_count; ++index)
        store_i64_le(output, index * 8, centers[index]);
    return static_cast<std::int64_t>(output_bytes);
}
