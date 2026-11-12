#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 6, max_generators = 4, max_queries = 8;
constexpr std::size_t max_input = 76;
constexpr int max_strong_generators = 32, max_pending = 8192;
using Code = std::uint32_t;
struct Layer {
    std::array<Code, max_strong_generators> generators{};
    int generator_count = 0;
    std::array<bool, max_n> in_orbit{};
    std::array<int, max_n> orbit{};
    int orbit_count = 0;
    std::array<Code, max_n> transversal{};
};
struct Pending { int level; Code value; };

Code identity(int n) {
    Code result = 0, place = 1;
    for (int point = 0; point < n; ++point, place *= 7) result += Code(point + 1) * place;
    return result;
}
Code encode(const std::array<int, max_n>& images, int n) {
    Code result = 0, place = 1;
    for (int point = 0; point < n; ++point, place *= 7) result += Code(images[point] + 1) * place;
    return result;
}
int image_of(Code value, int point) {
    while (point-- > 0) value /= 7;
    return int(value % 7) - 1;
}
Code compose(Code first, Code second, int n) {
    std::array<int, max_n> images{};
    for (int point = 0; point < n; ++point) images[point] = image_of(second, image_of(first, point));
    return encode(images, n);
}
Code inverse(Code value, int n) {
    std::array<int, max_n> images{};
    for (int point = 0; point < n; ++point) images[image_of(value, point)] = point;
    return encode(images, n);
}
bool append_generator(Layer& layer, Code value) {
    for (int i = 0; i < layer.generator_count; ++i) if (layer.generators[i] == value) return true;
    if (layer.generator_count == max_strong_generators) return false;
    layer.generators[layer.generator_count++] = value;
    return true;
}
void rebuild_orbit(Layer& layer, int base, int n, Code id) {
    layer.in_orbit.fill(false);
    layer.orbit[0] = base; layer.orbit_count = 1; layer.in_orbit[base] = true;
    layer.transversal[base] = id;
    for (int at = 0; at < layer.orbit_count; ++at) {
        const int point = layer.orbit[at];
        for (int g = 0; g < layer.generator_count; ++g) {
            const Code generator = layer.generators[g];
            const int image = image_of(generator, point);
            if (!layer.in_orbit[image]) {
                layer.in_orbit[image] = true;
                layer.transversal[image] = compose(layer.transversal[point], generator, n);
                layer.orbit[layer.orbit_count++] = image;
            }
        }
    }
}
bool build_chain(std::array<Layer, max_n>& layers, int n,
                 const std::array<Code, max_generators>& generators, int count) {
    const Code id = identity(n);
    std::array<Pending, max_pending> pending{};
    std::size_t head = 0, tail = 0;
    for (int i = 0; i < count; ++i) pending[tail++] = {0, generators[i]};
    while (head < tail) {
        const Pending item = pending[head++];
        Code residue = item.value;
        int level = item.level;
        for (; level < n; ++level) {
            const int image = image_of(residue, level);
            Layer& layer = layers[level];
            if (!layer.in_orbit[image]) break;
            residue = compose(residue, inverse(layer.transversal[image], n), n);
        }
        if (residue == id || level == n) continue;
        Layer& layer = layers[level];
        const Code inv = inverse(residue, n);
        if (!append_generator(layer, residue) || !append_generator(layer, inv)) return false;
        rebuild_orbit(layer, level, n, id);
        if (level + 1 < n) {
            for (int orbit_index = 0; orbit_index < layer.orbit_count; ++orbit_index) {
                const int point = layer.orbit[orbit_index];
                for (int g = 0; g < layer.generator_count; ++g) {
                    const Code generator = layer.generators[g];
                    const int image = image_of(generator, point);
                    const Code schreier = compose(compose(layer.transversal[point], generator, n),
                                                   inverse(layer.transversal[image], n), n);
                    if (schreier != id) {
                        if (tail == max_pending) return false;
                        pending[tail++] = {level + 1, schreier};
                    }
                }
            }
        }
    }
    return true;
}
bool is_member(const std::array<Layer, max_n>& layers, Code value, int n) {
    Code residue = value;
    const Code id = identity(n);
    for (int level = 0; level < n; ++level) {
        const int image = image_of(residue, level);
        const Layer& layer = layers[level];
        if (!layer.in_orbit[image]) return false;
        residue = compose(residue, inverse(layer.transversal[image], n), n);
    }
    return residue == id;
}
bool read_permutation(const std::int64_t* input, std::size_t offset, int n, Code& result) {
    std::array<bool, max_n> used{};
    std::array<int, max_n> images{};
    for (int point = 0; point < n; ++point) {
        const auto image = input[offset + std::size_t(point)];
        if (image < 0 || image >= n || used[std::size_t(image)]) return false;
        used[std::size_t(image)] = true; images[point] = int(image);
    }
    result = encode(images, n);
    return true;
}
void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = std::uint8_t(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t schreier_sims(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto nv = input[0], mv = input[1], qv = input[2];
    if (nv < 1 || nv > max_n || mv < 0 || mv > max_generators || qv < 1 || qv > max_queries) return -1;
    const int n = int(nv), m = int(mv), q = int(qv);
    if (length != 3 + std::size_t(n) * std::size_t(m + q)) return -1;
    std::array<Code, max_generators> generators{};
    std::array<Code, max_queries> queries{};
    std::size_t cursor = 3;
    for (int i = 0; i < m; ++i, cursor += std::size_t(n)) if (!read_permutation(input, cursor, n, generators[i])) return -1;
    for (int i = 0; i < q; ++i, cursor += std::size_t(n)) if (!read_permutation(input, cursor, n, queries[i])) return -1;
    const std::size_t required = 8 * std::size_t(q + 1);
    if (output == nullptr || capacity < required) return -2;
    std::array<Layer, max_n> layers{};
    const Code id = identity(n);
    for (int level = 0; level < n; ++level) {
        layers[level].in_orbit[level] = true;
        layers[level].orbit[0] = level; layers[level].orbit_count = 1;
        layers[level].transversal[level] = id;
    }
    if (!build_chain(layers, n, generators, m)) return -1;
    std::int64_t order = 1;
    for (int level = 0; level < n; ++level) order *= layers[level].orbit_count;
    store_le(output, 0, order);
    for (int i = 0; i < q; ++i) store_le(output, 8 * std::size_t(i + 1), is_member(layers, queries[i], n) ? 1 : 0);
    return std::int64_t(required);
}
