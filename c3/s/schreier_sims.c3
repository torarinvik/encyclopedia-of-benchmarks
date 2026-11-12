module schreier_sims;

const usz MAX_N = 6;
const usz MAX_GENERATORS = 4;
const usz MAX_QUERIES = 8;
const usz MAX_INPUT = 76;
const usz MAX_STRONG_GENERATORS = 32;
const usz MAX_PENDING = 8192;
alias Code = uint;

struct Layer {
    Code[MAX_STRONG_GENERATORS] generators;
    usz generator_count;
    bool[MAX_N] in_orbit;
    usz[MAX_N] orbit;
    usz orbit_count;
    Code[MAX_N] transversal;
}
struct Pending { usz level; Code value; }

fn Code identity(usz n) {
    Code result = 0, place = 1;
    for (usz point = 0; point < n; point++) { result += Code(point + 1) * place; place *= 7; }
    return result;
}
fn Code encode(usz[MAX_N]* images, usz n) {
    Code result = 0, place = 1;
    for (usz point = 0; point < n; point++) { result += Code(images[point] + 1) * place; place *= 7; }
    return result;
}
fn usz image_of(Code value, usz point) {
    for (; point > 0; point--) value /= 7;
    return usz(value % 7 - 1);
}
fn Code compose(Code first, Code second, usz n) {
    usz[MAX_N] images = {0};
    for (usz point = 0; point < n; point++) images[point] = image_of(second, image_of(first, point));
    return encode(&images[0], n);
}
fn Code inverse(Code value, usz n) {
    usz[MAX_N] images = {0};
    for (usz point = 0; point < n; point++) images[image_of(value, point)] = point;
    return encode(&images[0], n);
}
fn bool append_generator(Layer* layer, Code value) {
    for (usz i = 0; i < layer.generator_count; i++) if (layer.generators[i] == value) return true;
    if (layer.generator_count >= MAX_STRONG_GENERATORS) return false;
    layer.generators[layer.generator_count++] = value;
    return true;
}
fn void rebuild_orbit(Layer* layer, usz base, usz n, Code id) {
    for (usz point = 0; point < n; point++) layer.in_orbit[point] = false;
    layer.orbit_count = 1;
    layer.orbit[0] = base;
    layer.in_orbit[base] = true;
    layer.transversal[base] = id;
    for (usz at = 0; at < layer.orbit_count; at++) {
        usz point = layer.orbit[at];
        Code representative = layer.transversal[point];
        for (usz g = 0; g < layer.generator_count; g++) {
            Code generator = layer.generators[g];
            usz image = image_of(generator, point);
            if (!layer.in_orbit[image]) {
                layer.in_orbit[image] = true;
                layer.transversal[image] = compose(representative, generator, n);
                layer.orbit[layer.orbit_count++] = image;
            }
        }
    }
}
fn bool build_chain(Layer* layers, usz n, Code[MAX_GENERATORS]* generators, usz count) {
    Code id = identity(n);
    Pending[MAX_PENDING] pending = {0};
    usz head = 0, tail = 0;
    for (usz i = 0; i < count; i++) pending[tail++] = {0, generators[i]};
    while (head < tail) {
        Pending item = pending[head++];
        Code residue = item.value;
        usz level = item.level;
        for (; level < n; level++) {
            usz image = image_of(residue, level);
            Layer* layer = &layers[level];
            if (!layer.in_orbit[image]) break;
            residue = compose(residue, inverse(layer.transversal[image], n), n);
        }
        if (residue == id || level == n) continue;
        Layer* layer = &layers[level];
        Code inv = inverse(residue, n);
        if (!append_generator(layer, residue) || !append_generator(layer, inv)) return false;
        rebuild_orbit(layer, level, n, id);
        if (level + 1 < n) {
            usz orbit_count = layer.orbit_count;
            usz generator_count = layer.generator_count;
            for (usz orbit_index = 0; orbit_index < orbit_count; orbit_index++) {
                usz point = layer.orbit[orbit_index];
                Code representative = layer.transversal[point];
                for (usz g = 0; g < generator_count; g++) {
                    Code generator = layer.generators[g];
                    usz image = image_of(generator, point);
                    Code schreier = compose(compose(representative, generator, n), inverse(layer.transversal[image], n), n);
                    if (schreier != id) {
                        if (tail >= MAX_PENDING) return false;
                        pending[tail++] = {level + 1, schreier};
                    }
                }
            }
        }
    }
    return true;
}
fn bool is_member(Layer* layers, Code value_input, usz n) {
    Code residue = value_input;
    for (usz level = 0; level < n; level++) {
        usz image = image_of(residue, level);
        Layer* layer = &layers[level];
        if (!layer.in_orbit[image]) return false;
        residue = compose(residue, inverse(layer.transversal[image], n), n);
    }
    return residue == identity(n);
}
fn bool read_permutation(long* input, usz offset, usz n, Code* result) {
    bool[MAX_N] used = {false};
    usz[MAX_N] images = {0};
    for (usz point = 0; point < n; point++) {
        long image = input[offset + point];
        if (image < 0 || image >= long(n) || used[usz(image)]) return false;
        used[usz(image)] = true;
        images[point] = usz(image);
    }
    *result = encode(&images[0], n);
    return true;
}
fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = ulong(value);
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = uint8(bits & 255); bits >>= 8; }
}

fn long schreier_sims(long* input, usz length, uint8* output, usz capacity) @export("schreier_sims") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long nv = input[0], mv = input[1], qv = input[2];
    if (nv < 1 || nv > long(MAX_N) || mv < 0 || mv > long(MAX_GENERATORS) || qv < 1 || qv > long(MAX_QUERIES)) return -1;
    usz n = usz(nv), m = usz(mv), q = usz(qv);
    if (length != 3 + n * (m + q)) return -1;
    Code[MAX_GENERATORS] generators = {0};
    Code[MAX_QUERIES] queries = {0};
    usz cursor = 3;
    for (usz i = 0; i < m; i++) {
        if (!read_permutation(input, cursor, n, &generators[i])) return -1;
        cursor += n;
    }
    for (usz i = 0; i < q; i++) {
        if (!read_permutation(input, cursor, n, &queries[i])) return -1;
        cursor += n;
    }
    usz required = 8 * (q + 1);
    if (output == null || capacity < required) return -2;
    Layer[MAX_N] layers = {0};
    Code id = identity(n);
    for (usz level = 0; level < n; level++) {
        layers[level].in_orbit[level] = true;
        layers[level].orbit[0] = level;
        layers[level].orbit_count = 1;
        layers[level].transversal[level] = id;
    }
    if (!build_chain(&layers[0], n, &generators[0], m)) return -1;
    long order = 1;
    for (usz level = 0; level < n; level++) order *= long(layers[level].orbit_count);
    store_le(output, 0, order);
    for (usz i = 0; i < q; i++) store_le(output, 8 * (i + 1), is_member(&layers[0], queries[i], n) ? 1 : 0);
    return long(required);
}
