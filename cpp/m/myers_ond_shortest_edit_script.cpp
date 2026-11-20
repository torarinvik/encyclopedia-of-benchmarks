#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_sequence = 16;
constexpr int max_distance = 32;
constexpr int max_output = 48;
constexpr int offset = 33;
constexpr int diagonals = 67;

struct Edit_Step { std::uint8_t operation; std::uint8_t symbol; };

int build_script(const std::int64_t* input, std::uint8_t* output) noexcept {
    const int n = static_cast<int>(input[0]);
    const int m = static_cast<int>(input[1]);
    const std::int64_t* first = input + 2;
    const std::int64_t* second = first + n;
    int frontier[diagonals];
    int trace[max_distance + 1][diagonals];
    for (int i = 0; i < diagonals; ++i) frontier[i] = -1;
    for (int d = 0; d <= max_distance; ++d)
        for (int i = 0; i < diagonals; ++i) trace[d][i] = -1;
    frontier[offset + 1] = 0;
    int found_d = -1;
    int found_k = 0;

    for (int d = 0; d <= n + m && found_d < 0; ++d) {
        for (int k = -d; k <= d; k += 2) {
            const int slot = offset + k;
            int x;
            if (k == -d || (k != d && frontier[slot - 1] < frontier[slot + 1]))
                x = frontier[slot + 1];
            else
                x = frontier[slot - 1] + 1;
            int y = x - k;
            while (x < n && y < m && first[x] == second[y]) { ++x; ++y; }
            frontier[slot] = x;
            trace[d][slot] = x;
            if (x >= n && y >= m) { found_d = d; found_k = k; break; }
        }
    }

    Edit_Step reverse_path[max_distance];
    int path_length = 0;
    int x = n, y = m, k = found_k;
    for (int d = found_d; d > 0; --d) {
        const int slot = offset + k;
        int previous_k, previous_x, previous_y, snake_x, snake_y;
        if (k == -d || (k != d && trace[d - 1][slot - 1] < trace[d - 1][slot + 1])) {
            previous_k = k + 1;
            previous_x = trace[d - 1][offset + previous_k];
            previous_y = previous_x - previous_k;
            snake_x = previous_x;
            snake_y = previous_y + 1;
            while (x > snake_x && y > snake_y) {
                reverse_path[path_length++] = {0, 0};
                --x; --y;
            }
            reverse_path[path_length++] = {2, static_cast<std::uint8_t>(second[previous_y])};
        } else {
            previous_k = k - 1;
            previous_x = trace[d - 1][offset + previous_k];
            previous_y = previous_x - previous_k;
            snake_x = previous_x + 1;
            snake_y = previous_y;
            while (x > snake_x && y > snake_y) {
                reverse_path[path_length++] = {0, 0};
                --x; --y;
            }
            reverse_path[path_length++] = {1, 0};
        }
        x = previous_x; y = previous_y; k = previous_k;
    }
    for (int i = 0; i < trace[0][offset]; ++i) reverse_path[path_length++] = {0, 0};
    int bytes = 0;
    for (int i = path_length - 1; i >= 0; --i) {
        output[bytes++] = reverse_path[i].operation;
        if (reverse_path[i].operation == 2) output[bytes++] = reverse_path[i].symbol;
    }
    return bytes;
}
} // namespace

extern "C" std::int64_t myers_ond_shortest_edit_script(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 2 + 2 * max_sequence) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 0 || n_value > max_sequence || m_value < 0 || m_value > max_sequence) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;

    std::uint8_t staged[max_output];
    const int needed = build_script(input, staged);
    if (output == nullptr || output_capacity < static_cast<std::size_t>(needed)) return -2;
    for (int i = 0; i < needed; ++i) output[i] = staged[i];
    return needed;
}
