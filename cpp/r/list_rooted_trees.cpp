#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_vertices = 7;
constexpr std::size_t max_shapes = 48;
constexpr std::size_t max_encoding = 14;
constexpr std::size_t max_width = max_encoding + 1;
constexpr std::size_t max_candidates = 37;
constexpr std::size_t max_output = 674;

struct Candidate {
    std::size_t size;
    const char* text;
};

struct Generator {
    std::array<std::array<std::array<char, max_width>, max_shapes>, max_vertices + 1> shapes{};
    std::array<std::size_t, max_vertices + 1> counts{};
    std::array<Candidate, max_candidates> candidates{};
    std::size_t candidate_count = 0;
    std::size_t target = 0;
};

void enumerate_multisets(Generator& generator, std::size_t start,
                         std::size_t remaining,
                         std::array<char, max_width>& children,
                         std::size_t child_length) noexcept {
    if (remaining == 0) {
        const auto index = generator.counts[generator.target];
        if (index >= max_shapes) return;
        auto& shape = generator.shapes[generator.target][index];
        shape[0] = '(';
        std::copy_n(children.data(), child_length, shape.data() + 1);
        shape[child_length + 1] = ')';
        shape[child_length + 2] = '\0';
        generator.counts[generator.target] = index + 1;
        return;
    }

    for (std::size_t index = start; index < generator.candidate_count; ++index) {
        const auto& candidate = generator.candidates[index];
        if (candidate.size > remaining) continue;
        const auto encoded_length = 2 * candidate.size;
        std::copy_n(candidate.text, encoded_length,
                    children.data() + child_length);
        enumerate_multisets(generator, index, remaining - candidate.size,
                            children, child_length + encoded_length);
    }
}

void build_shapes(Generator& generator, std::size_t maximum) {
    generator.counts[1] = 1;
    generator.shapes[1][0][0] = '(';
    generator.shapes[1][0][1] = ')';
    generator.shapes[1][0][2] = '\0';

    for (std::size_t target = 2; target <= maximum; ++target) {
        generator.target = target;
        generator.candidate_count = 0;
        for (std::size_t size = 1; size < target; ++size) {
            for (std::size_t index = 0; index < generator.counts[size]; ++index) {
                const Candidate candidate{size,
                    generator.shapes[size][index].data()};
                auto position = generator.candidate_count;
                while (position > 0 &&
                       std::strcmp(candidate.text,
                           generator.candidates[position - 1].text) < 0) {
                    generator.candidates[position] =
                        generator.candidates[position - 1];
                    --position;
                }
                generator.candidates[position] = candidate;
                ++generator.candidate_count;
            }
        }

        std::array<char, max_width> children{};
        enumerate_multisets(generator, 0, target - 1, children, 0);
        auto& level = generator.shapes[target];
        std::sort(level.begin(), level.begin() + generator.counts[target],
            [](const auto& left, const auto& right) {
                return std::strcmp(left.data(), right.data()) < 0;
            });
    }
}
}  // namespace

extern "C" std::int64_t list_rooted_trees(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices)) return -1;

    Generator generator{};
    const auto vertices = static_cast<std::size_t>(input[0]);
    build_shapes(generator, vertices);

    std::array<std::uint8_t, max_output> staged{};
    const auto count = generator.counts[vertices];
    staged[0] = static_cast<std::uint8_t>(count & 0xffU);
    staged[1] = static_cast<std::uint8_t>((count >> 8) & 0xffU);
    const auto width = 2 * vertices;
    std::size_t position = 2;
    for (std::size_t index = 0; index < count; ++index) {
        std::copy_n(generator.shapes[vertices][index].data(), width,
                    staged.data() + position);
        position += width;
    }

    if (output == nullptr || capacity < position) return -2;
    std::copy_n(staged.data(), position, output);
    return static_cast<std::int64_t>(position);
}
