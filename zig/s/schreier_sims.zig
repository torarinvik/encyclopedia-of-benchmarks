const MAX_N: usize = 6;
const MAX_GENERATORS: usize = 4;
const MAX_QUERIES: usize = 8;
const MAX_INPUT: usize = 76;
const MAX_STRONG_GENERATORS: usize = 32;
const MAX_PENDING: usize = 8192;
const Code = u32;

const Layer = struct {
    generators: [MAX_STRONG_GENERATORS]Code = @splat(0),
    generator_count: usize = 0,
    in_orbit: [MAX_N]bool = @splat(false),
    orbit: [MAX_N]usize = @splat(0),
    orbit_count: usize = 0,
    transversal: [MAX_N]Code = @splat(0),
};
const Pending = struct { level: usize = 0, value: Code = 0 };

fn identity(n: usize) Code {
    var result: Code = 0;
    var place: Code = 1;
    for (0..n) |point| { result += @as(Code, @intCast(point + 1)) * place; place *= 7; }
    return result;
}
fn encode(images: *const [MAX_N]usize, n: usize) Code {
    var result: Code = 0;
    var place: Code = 1;
    for (0..n) |point| { result += @as(Code, @intCast(images[point] + 1)) * place; place *= 7; }
    return result;
}
fn imageOf(value_input: Code, point_input: usize) usize {
    var value = value_input;
    var point = point_input;
    while (point > 0) : (point -= 1) value /= 7;
    return @intCast(value % 7 - 1);
}
fn compose(first: Code, second: Code, n: usize) Code {
    var images: [MAX_N]usize = @splat(0);
    for (0..n) |point| images[point] = imageOf(second, imageOf(first, point));
    return encode(&images, n);
}
fn inverse(value: Code, n: usize) Code {
    var images: [MAX_N]usize = @splat(0);
    for (0..n) |point| images[imageOf(value, point)] = point;
    return encode(&images, n);
}
fn appendGenerator(layer: *Layer, value: Code) bool {
    for (0..layer.generator_count) |i| if (layer.generators[i] == value) return true;
    if (layer.generator_count >= MAX_STRONG_GENERATORS) return false;
    layer.generators[layer.generator_count] = value;
    layer.generator_count += 1;
    return true;
}
fn rebuildOrbit(layer: *Layer, base: usize, n: usize, id: Code) void {
    layer.in_orbit = @splat(false);
    layer.orbit_count = 1;
    layer.orbit[0] = base;
    layer.in_orbit[base] = true;
    layer.transversal[base] = id;
    var at: usize = 0;
    while (at < layer.orbit_count) : (at += 1) {
        const point = layer.orbit[at];
        const representative = layer.transversal[point];
        for (0..layer.generator_count) |g| {
            const generator = layer.generators[g];
            const image = imageOf(generator, point);
            if (!layer.in_orbit[image]) {
                layer.in_orbit[image] = true;
                layer.transversal[image] = compose(representative, generator, n);
                layer.orbit[layer.orbit_count] = image;
                layer.orbit_count += 1;
            }
        }
    }
}
fn buildChain(layers: *[MAX_N]Layer, n: usize, generators: *const [MAX_GENERATORS]Code, count: usize) bool {
    const id = identity(n);
    var pending: [MAX_PENDING]Pending = @splat(.{});
    var head: usize = 0;
    var tail: usize = 0;
    for (0..count) |i| { pending[tail] = .{ .level = 0, .value = generators[i] }; tail += 1; }
    while (head < tail) {
        const item = pending[head]; head += 1;
        var residue = item.value;
        var level = item.level;
        while (level < n) {
            const image = imageOf(residue, level);
            if (!layers[level].in_orbit[image]) break;
            residue = compose(residue, inverse(layers[level].transversal[image], n), n);
            level += 1;
        }
        if (residue == id or level == n) continue;
        const inv = inverse(residue, n);
        if (!appendGenerator(&layers[level], residue) or !appendGenerator(&layers[level], inv)) return false;
        rebuildOrbit(&layers[level], level, n, id);
        if (level + 1 < n) {
            const orbit_count = layers[level].orbit_count;
            const generator_count = layers[level].generator_count;
            for (0..orbit_count) |orbit_index| {
                const point = layers[level].orbit[orbit_index];
                const representative = layers[level].transversal[point];
                for (0..generator_count) |g| {
                    const generator = layers[level].generators[g];
                    const image = imageOf(generator, point);
                    const schreier = compose(compose(representative, generator, n),
                        inverse(layers[level].transversal[image], n), n);
                    if (schreier != id) {
                        if (tail >= MAX_PENDING) return false;
                        pending[tail] = .{ .level = level + 1, .value = schreier };
                        tail += 1;
                    }
                }
            }
        }
    }
    return true;
}
fn isMember(layers: *const [MAX_N]Layer, value_input: Code, n: usize) bool {
    var residue = value_input;
    const id = identity(n);
    for (0..n) |level| {
        const image = imageOf(residue, level);
        if (!layers[level].in_orbit[image]) return false;
        residue = compose(residue, inverse(layers[level].transversal[image], n), n);
    }
    return residue == id;
}
fn readPermutation(input: [*c]const i64, offset: usize, n: usize) ?Code {
    var used: [MAX_N]bool = @splat(false);
    var images: [MAX_N]usize = @splat(0);
    for (0..n) |point| {
        const image = input[offset + point];
        if (image < 0 or image >= @as(i64, @intCast(n)) or used[@intCast(image)]) return null;
        used[@intCast(image)] = true;
        images[point] = @intCast(image);
    }
    return encode(&images, n);
}
fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn schreier_sims(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const m_value = packed[1];
    const q_value = packed[2];
    if (n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_GENERATORS or q_value < 1 or q_value > MAX_QUERIES) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const q: usize = @intCast(q_value);
    if (length != 3 + n * (m + q)) return -1;
    var generators: [MAX_GENERATORS]Code = @splat(0);
    var queries: [MAX_QUERIES]Code = @splat(0);
    var cursor: usize = 3;
    for (0..m) |i| {
        generators[i] = readPermutation(input, cursor, n) orelse return -1;
        cursor += n;
    }
    for (0..q) |i| {
        queries[i] = readPermutation(input, cursor, n) orelse return -1;
        cursor += n;
    }
    const required = 8 * (q + 1);
    if (output == null or capacity < required) return -2;
    var layers: [MAX_N]Layer = @splat(.{});
    const id = identity(n);
    for (0..n) |level| {
        layers[level].in_orbit[level] = true;
        layers[level].orbit[0] = level;
        layers[level].orbit_count = 1;
        layers[level].transversal[level] = id;
    }
    if (!buildChain(&layers, n, &generators, m)) return -1;
    var order: i64 = 1;
    for (0..n) |level| order *= @intCast(layers[level].orbit_count);
    storeLe(output, 0, order);
    for (0..q) |i| storeLe(output, 8 * (i + 1), if (isMember(&layers, queries[i], n)) 1 else 0);
    return @intCast(required);
}
