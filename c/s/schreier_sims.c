#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_GENERATORS = 4, MAX_QUERIES = 8,
       MAX_INPUT = 76, MAX_STRONG_GENERATORS = 32, MAX_PENDING = 8192 };
typedef uint32_t permutation_code;

typedef struct {
    permutation_code generators[MAX_STRONG_GENERATORS];
    int generator_count;
    bool in_orbit[MAX_N];
    int orbit[MAX_N];
    int orbit_count;
    permutation_code transversal[MAX_N];
} chain_layer;
typedef struct { int level; permutation_code value; } pending_generator;

static permutation_code identity(int n) {
    permutation_code result = 0, place = 1;
    for (int point = 0; point < n; ++point) {
        result += (permutation_code)(point + 1) * place;
        place *= 7;
    }
    return result;
}

static permutation_code encode(const int images[MAX_N], int n) {
    permutation_code result = 0, place = 1;
    for (int point = 0; point < n; ++point) {
        result += (permutation_code)(images[point] + 1) * place;
        place *= 7;
    }
    return result;
}

static int image_of(permutation_code value, int point) {
    while (point-- > 0) value /= 7;
    return (int)(value % 7) - 1;
}

static permutation_code compose(permutation_code first, permutation_code second, int n) {
    int images[MAX_N];
    for (int point = 0; point < n; ++point)
        images[point] = image_of(second, image_of(first, point));
    return encode(images, n);
}

static permutation_code inverse(permutation_code value, int n) {
    int images[MAX_N] = {0};
    for (int point = 0; point < n; ++point) images[image_of(value, point)] = point;
    return encode(images, n);
}

static bool append_generator(chain_layer *layer, permutation_code value) {
    for (int i = 0; i < layer->generator_count; ++i)
        if (layer->generators[i] == value) return true;
    if (layer->generator_count >= MAX_STRONG_GENERATORS) return false;
    layer->generators[layer->generator_count++] = value;
    return true;
}

static void rebuild_orbit(chain_layer *layer, int base, int n,
                          permutation_code id) {
    for (int point = 0; point < n; ++point) layer->in_orbit[point] = false;
    layer->orbit_count = 1;
    layer->orbit[0] = base;
    layer->in_orbit[base] = true;
    layer->transversal[base] = id;
    for (int at = 0; at < layer->orbit_count; ++at) {
        const int point = layer->orbit[at];
        for (int g = 0; g < layer->generator_count; ++g) {
            const permutation_code generator = layer->generators[g];
            const int image = image_of(generator, point);
            if (!layer->in_orbit[image]) {
                layer->in_orbit[image] = true;
                layer->transversal[image] = compose(layer->transversal[point], generator, n);
                layer->orbit[layer->orbit_count++] = image;
            }
        }
    }
}

static bool build_chain(chain_layer layers[MAX_N], int n,
                        const permutation_code generators[MAX_GENERATORS], int count) {
    const permutation_code id = identity(n);
    pending_generator pending[MAX_PENDING];
    size_t head = 0, tail = 0;
    for (int i = 0; i < count; ++i) pending[tail++] = (pending_generator){0, generators[i]};

    while (head < tail) {
        const pending_generator item = pending[head++];
        permutation_code residue = item.value;
        int level = item.level;
        for (; level < n; ++level) {
            const int image = image_of(residue, level);
            chain_layer *layer = &layers[level];
            if (!layer->in_orbit[image]) break;
            residue = compose(residue, inverse(layer->transversal[image], n), n);
        }
        if (residue == id || level == n) continue;

        chain_layer *layer = &layers[level];
        const permutation_code inverse_residue = inverse(residue, n);
        if (!append_generator(layer, residue)) return false;
        if (!append_generator(layer, inverse_residue)) return false;
        rebuild_orbit(layer, level, n, id);

        if (level + 1 < n) {
            for (int orbit_index = 0; orbit_index < layer->orbit_count; ++orbit_index) {
                const int point = layer->orbit[orbit_index];
                for (int g = 0; g < layer->generator_count; ++g) {
                    const permutation_code generator = layer->generators[g];
                    const int image = image_of(generator, point);
                    const permutation_code schreier = compose(
                        compose(layer->transversal[point], generator, n),
                        inverse(layer->transversal[image], n), n);
                    if (schreier != id) {
                        if (tail >= MAX_PENDING) return false;
                        pending[tail++] = (pending_generator){level + 1, schreier};
                    }
                }
            }
        }
    }
    return true;
}

static bool is_member(const chain_layer layers[MAX_N], permutation_code value, int n) {
    const permutation_code id = identity(n);
    permutation_code residue = value;
    for (int level = 0; level < n; ++level) {
        const int image = image_of(residue, level);
        const chain_layer *layer = &layers[level];
        if (!layer->in_orbit[image]) return false;
        residue = compose(residue, inverse(layer->transversal[image], n), n);
    }
    return residue == id;
}

static bool read_permutation(const int64_t *input, size_t offset, int n,
                             permutation_code *result) {
    bool used[MAX_N] = {false};
    int images[MAX_N] = {0};
    for (int point = 0; point < n; ++point) {
        const int64_t image = input[offset + (size_t)point];
        if (image < 0 || image >= n || used[(size_t)image]) return false;
        used[(size_t)image] = true;
        images[point] = (int)image;
    }
    *result = encode(images, n);
    return true;
}

static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t schreier_sims(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], m_value = input[1], q_value = input[2];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_GENERATORS ||
        q_value < 1 || q_value > MAX_QUERIES) return -1;
    const int n = (int)n_value, m = (int)m_value, q = (int)q_value;
    if (length != 3u + (size_t)n * (size_t)(m + q)) return -1;

    permutation_code generators[MAX_GENERATORS] = {0};
    permutation_code queries[MAX_QUERIES] = {0};
    size_t cursor = 3;
    for (int i = 0; i < m; ++i) {
        if (!read_permutation(input, cursor, n, &generators[i])) return -1;
        cursor += (size_t)n;
    }
    for (int i = 0; i < q; ++i) {
        if (!read_permutation(input, cursor, n, &queries[i])) return -1;
        cursor += (size_t)n;
    }

    const size_t required = 8u * (size_t)(q + 1);
    if (output == NULL || capacity < required) return -2;
    chain_layer layers[MAX_N] = {0};
    for (int level = 0; level < n; ++level) {
        layers[level].in_orbit[level] = true;
        layers[level].orbit[0] = level;
        layers[level].orbit_count = 1;
        layers[level].transversal[level] = identity(n);
    }
    if (!build_chain(layers, n, generators, m)) return -1;

    int64_t group_order = 1;
    for (int level = 0; level < n; ++level) group_order *= layers[level].orbit_count;
    store_le(output, 0, group_order);
    for (int i = 0; i < q; ++i)
        store_le(output, 8u * (size_t)(i + 1), is_member(layers, queries[i], n) ? 1 : 0);
    return (int64_t)required;
}
