#include <cstddef>
#include <cstdint>

namespace {
constexpr unsigned max_vertices = 8;
constexpr std::size_t max_input_length = 9;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t degree_color_place = 43046721;

unsigned popcount_u64(std::uint64_t value) {
    unsigned count = 0;
    while (value != 0) {
        count += static_cast<unsigned>(value & 1U);
        value >>= 1U;
    }
    return count;
}
}

extern "C" std::int64_t weisfeiler_lehman_color_refinement(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_input_length + 1) return invalid_result;
    if (input[0] < 0 || input[0] > max_vertices) return invalid_result;
    const unsigned n = static_cast<unsigned>(input[0]);
    if (length != 1 + n) return invalid_result;

    std::uint64_t adjacency[max_vertices]{};
    const std::uint64_t allowed = (std::uint64_t{1} << n) - 1U;
    std::int64_t colors[max_vertices]{};
    std::int64_t next_colors[max_vertices]{};
    unsigned class_count = 0;
    for (unsigned vertex = 0; vertex < n; ++vertex) {
        if (input[1 + vertex] < 0) return invalid_result;
        adjacency[vertex] = static_cast<std::uint64_t>(input[1 + vertex]);
        if ((adjacency[vertex] & ~allowed) != 0 ||
            (adjacency[vertex] & (std::uint64_t{1} << vertex)) != 0) return invalid_result;
        colors[vertex] = static_cast<std::int64_t>(popcount_u64(adjacency[vertex]));
        bool first_degree = true;
        for (unsigned prior = 0; prior < vertex; ++prior) {
            if (static_cast<std::int64_t>(popcount_u64(adjacency[prior])) == colors[vertex])
                first_degree = false;
            if (((adjacency[vertex] >> prior) & 1U) != ((adjacency[prior] >> vertex) & 1U))
                return invalid_result;
        }
        if (first_degree) ++class_count;
    }
    if (n == 0) return 0;

    for (;;) {
        std::int64_t keys[max_vertices]{};
        std::int64_t unique_keys[max_vertices]{};
        unsigned unique_count = 0;
        for (unsigned vertex = 0; vertex < n; ++vertex) {
            std::int64_t neighbor_colors[max_vertices]{};
            unsigned neighbor_count = 0;
            for (unsigned neighbor = 0; neighbor < n; ++neighbor) {
                if ((adjacency[vertex] & (std::uint64_t{1} << neighbor)) == 0) continue;
                const std::int64_t value = colors[neighbor];
                unsigned position = neighbor_count;
                while (position > 0 && neighbor_colors[position - 1] > value) {
                    neighbor_colors[position] = neighbor_colors[position - 1];
                    --position;
                }
                neighbor_colors[position] = value;
                ++neighbor_count;
            }
            std::int64_t suffix = 0;
            for (unsigned slot = 0; slot < max_vertices; ++slot) {
                suffix *= 9;
                if (slot < neighbor_count) suffix += neighbor_colors[slot] + 1;
            }
            keys[vertex] = colors[vertex] * degree_color_place + suffix;

            bool seen = false;
            for (unsigned prior = 0; prior < vertex; ++prior)
                if (keys[prior] == keys[vertex]) seen = true;
            if (!seen) unique_keys[unique_count++] = keys[vertex];
        }

        for (unsigned index = 1; index < unique_count; ++index) {
            const std::int64_t value = unique_keys[index];
            unsigned position = index;
            while (position > 0 && unique_keys[position - 1] > value) {
                unique_keys[position] = unique_keys[position - 1];
                --position;
            }
            unique_keys[position] = value;
        }
        for (unsigned vertex = 0; vertex < n; ++vertex) {
            unsigned rank = 0;
            while (unique_keys[rank] != keys[vertex]) ++rank;
            next_colors[vertex] = static_cast<std::int64_t>(rank);
        }
        if (unique_count == class_count) {
            for (unsigned vertex = 0; vertex < n; ++vertex) colors[vertex] = next_colors[vertex];
            break;
        }
        for (unsigned vertex = 0; vertex < n; ++vertex) colors[vertex] = next_colors[vertex];
        class_count = unique_count;
    }

    std::int64_t packed = 0;
    std::int64_t place = 1;
    for (unsigned vertex = 0; vertex < n; ++vertex) {
        packed += colors[vertex] * place;
        place *= 9;
    }
    return packed;
}
