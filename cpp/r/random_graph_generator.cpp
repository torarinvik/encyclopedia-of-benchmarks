/* Replay bounded random_graph edge decisions into a row-major adjacency matrix. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_parseable_input_length = 2020;
constexpr std::size_t max_output_bytes = 4096;
constexpr std::int64_t draw_scale = INT64_C(9007199254740992);
constexpr std::int64_t min_probability_units = -draw_scale;
constexpr std::int64_t max_probability_units = INT64_C(18014398509481984);
}

extern "C" std::int64_t random_graph_generator(const std::int64_t* input, std::size_t input_length,
                                                 std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 3 || input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_vertices) ||
        (input[1] != 0 && input[1] != 1) ||
        input[2] < min_probability_units || input[2] > max_probability_units) return -1;

    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto directed = input[1];
    const auto probability_units = input[2];
    const std::size_t pair_count = vertex_count < 2 ? 0 : vertex_count * (vertex_count - 1) / 2;
    const std::size_t draw_count = probability_units > 0 && probability_units < draw_scale ? pair_count : 0;
    if (input_length != 3 + draw_count) return -1;
    for (std::size_t index = 0; index < draw_count; ++index)
        if (input[3 + index] < 0 || input[3 + index] >= draw_scale) return -1;

    std::uint8_t staged[max_output_bytes]{};
    if (probability_units >= draw_scale) {
        for (std::size_t source = 0; source < vertex_count; ++source)
            for (std::size_t target = 0; target < vertex_count; ++target)
                if (source != target) staged[source * vertex_count + target] = 1;
    } else if (probability_units > 0) {
        std::size_t draw_index = 0;
        for (std::size_t source = 0; source < vertex_count; ++source) {
            for (std::size_t target = source + 1; target < vertex_count; ++target) {
                if (input[3 + draw_index] < probability_units) {
                    staged[source * vertex_count + target] = 1;
                    if (directed == 0) staged[target * vertex_count + source] = 1;
                }
                ++draw_index;
            }
        }
    }

    const std::size_t output_bytes = vertex_count * vertex_count;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
