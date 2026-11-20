#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cherry_pickup_ii(const std::int64_t *input, std::size_t length) {
    constexpr std::size_t max_dim = 6;
    if (input == nullptr || length < 6 || length > 39) return -1;
    const auto rows_value = input[0], columns_value = input[1];
    if (rows_value < 2 || rows_value > max_dim || columns_value < 2 || columns_value > max_dim) return -1;
    const auto rows = static_cast<std::size_t>(rows_value), columns = static_cast<std::size_t>(columns_value);
    if (length != 2 + rows * columns) return -1;
    for (std::size_t i = 0; i < rows * columns; ++i) if (input[2 + i] < 0 || input[2 + i] > 100) return -1;
    std::int64_t previous[max_dim * max_dim], current[max_dim * max_dim];
    for (auto &value : previous) value = -1;
    previous[columns - 1] = input[2] + input[2 + columns - 1];
    for (std::size_t row = 1; row < rows; ++row) {
        for (auto &value : current) value = -1;
        for (std::size_t left = 0; left < columns; ++left) {
            for (std::size_t right = 0; right < columns; ++right) {
                const auto score = previous[left * columns + right];
                if (score < 0) continue;
                for (int dl = -1; dl <= 1; ++dl) {
                    const int next_left_i = static_cast<int>(left) + dl;
                    if (next_left_i < 0 || next_left_i >= static_cast<int>(columns)) continue;
                    const auto next_left = static_cast<std::size_t>(next_left_i);
                    for (int dr = -1; dr <= 1; ++dr) {
                        const int next_right_i = static_cast<int>(right) + dr;
                        if (next_right_i < 0 || next_right_i >= static_cast<int>(columns)) continue;
                        const auto next_right = static_cast<std::size_t>(next_right_i);
                        auto candidate = score + input[2 + row * columns + next_left];
                        if (next_left != next_right) candidate += input[2 + row * columns + next_right];
                        auto &destination = current[next_left * columns + next_right];
                        if (candidate > destination) destination = candidate;
                    }
                }
            }
        }
        for (std::size_t i = 0; i < max_dim * max_dim; ++i) previous[i] = current[i];
    }
    std::int64_t answer = -1;
    for (std::size_t left = 0; left < columns; ++left)
        for (std::size_t right = 0; right < columns; ++right)
            if (previous[left * columns + right] > answer) answer = previous[left * columns + right];
    return answer;
}
