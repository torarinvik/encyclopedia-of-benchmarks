const MAX_N: usize = 6;
const MAX_GENERATORS: usize = 4;
const MAX_QUERIES: usize = 8;
const MAX_INPUT: usize = 76;
const MAX_STRONG_GENERATORS: usize = 32;
const MAX_PENDING: usize = 8192;
type Code = u32;

#[derive(Clone, Copy, Default)]
struct Layer {
    generators: [Code; MAX_STRONG_GENERATORS],
    generator_count: usize,
    in_orbit: [bool; MAX_N],
    orbit: [usize; MAX_N],
    orbit_count: usize,
    transversal: [Code; MAX_N],
}
#[derive(Clone, Copy, Default)]
struct Pending { level: usize, value: Code }

fn identity(n: usize) -> Code {
    let mut result = 0;
    let mut place = 1;
    for point in 0..n { result += (point as Code + 1) * place; place *= 7; }
    result
}
fn encode(images: &[usize; MAX_N], n: usize) -> Code {
    let mut result = 0;
    let mut place = 1;
    for point in 0..n { result += (images[point] as Code + 1) * place; place *= 7; }
    result
}
fn image_of(mut value: Code, point: usize) -> usize {
    for _ in 0..point { value /= 7; }
    (value % 7 - 1) as usize
}
fn compose(first: Code, second: Code, n: usize) -> Code {
    let mut images = [0usize; MAX_N];
    for point in 0..n { images[point] = image_of(second, image_of(first, point)); }
    encode(&images, n)
}
fn inverse(value: Code, n: usize) -> Code {
    let mut images = [0usize; MAX_N];
    for point in 0..n { images[image_of(value, point)] = point; }
    encode(&images, n)
}
fn append_generator(layer: &mut Layer, value: Code) -> bool {
    if layer.generators[..layer.generator_count].contains(&value) { return true; }
    if layer.generator_count == MAX_STRONG_GENERATORS { return false; }
    layer.generators[layer.generator_count] = value;
    layer.generator_count += 1;
    true
}
fn rebuild_orbit(layer: &mut Layer, base: usize, n: usize, id: Code) {
    layer.in_orbit = [false; MAX_N];
    layer.orbit_count = 1;
    layer.orbit[0] = base;
    layer.in_orbit[base] = true;
    layer.transversal[base] = id;
    let mut at = 0;
    while at < layer.orbit_count {
        let point = layer.orbit[at];
        at += 1;
        let representative = layer.transversal[point];
        for g in 0..layer.generator_count {
            let generator = layer.generators[g];
            let image = image_of(generator, point);
            if !layer.in_orbit[image] {
                layer.in_orbit[image] = true;
                layer.transversal[image] = compose(representative, generator, n);
                layer.orbit[layer.orbit_count] = image;
                layer.orbit_count += 1;
            }
        }
    }
}
fn build_chain(layers: &mut [Layer; MAX_N], n: usize, generators: &[Code; MAX_GENERATORS], count: usize) -> bool {
    let id = identity(n);
    let mut pending = [Pending::default(); MAX_PENDING];
    let mut head = 0;
    let mut tail = 0;
    for i in 0..count { pending[tail] = Pending { level: 0, value: generators[i] }; tail += 1; }
    while head < tail {
        let item = pending[head]; head += 1;
        let mut residue = item.value;
        let mut level = item.level;
        while level < n {
            let image = image_of(residue, level);
            if !layers[level].in_orbit[image] { break; }
            residue = compose(residue, inverse(layers[level].transversal[image], n), n);
            level += 1;
        }
        if residue == id || level == n { continue; }
        let inv = inverse(residue, n);
        if !append_generator(&mut layers[level], residue) || !append_generator(&mut layers[level], inv) { return false; }
        rebuild_orbit(&mut layers[level], level, n, id);
        if level + 1 < n {
            let orbit_count = layers[level].orbit_count;
            let generator_count = layers[level].generator_count;
            for orbit_index in 0..orbit_count {
                let point = layers[level].orbit[orbit_index];
                let representative = layers[level].transversal[point];
                for g in 0..generator_count {
                    let generator = layers[level].generators[g];
                    let image = image_of(generator, point);
                    let schreier = compose(compose(representative, generator, n),
                                           inverse(layers[level].transversal[image], n), n);
                    if schreier != id {
                        if tail == MAX_PENDING { return false; }
                        pending[tail] = Pending { level: level + 1, value: schreier };
                        tail += 1;
                    }
                }
            }
        }
    }
    true
}
fn is_member(layers: &[Layer; MAX_N], mut residue: Code, n: usize) -> bool {
    let id = identity(n);
    for level in 0..n {
        let image = image_of(residue, level);
        if !layers[level].in_orbit[image] { return false; }
        residue = compose(residue, inverse(layers[level].transversal[image], n), n);
    }
    residue == id
}
fn read_permutation(input: &[i64], offset: usize, n: usize) -> Option<Code> {
    let mut used = [false; MAX_N];
    let mut images = [0usize; MAX_N];
    for point in 0..n {
        let image = input[offset + point];
        if image < 0 || image >= n as i64 || used[image as usize] { return None; }
        used[image as usize] = true;
        images[point] = image as usize;
    }
    Some(encode(&images, n))
}
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn schreier_sims(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0]; let mv = values[1]; let qv = values[2];
    if nv < 1 || nv > MAX_N as i64 || mv < 0 || mv > MAX_GENERATORS as i64 || qv < 1 || qv > MAX_QUERIES as i64 { return -1; }
    let n = nv as usize; let m = mv as usize; let q = qv as usize;
    if length != 3 + n * (m + q) { return -1; }
    let mut generators = [0; MAX_GENERATORS];
    let mut queries = [0; MAX_QUERIES];
    let mut cursor = 3;
    for slot in generators.iter_mut().take(m) {
        let Some(value) = read_permutation(values, cursor, n) else { return -1; };
        *slot = value; cursor += n;
    }
    for slot in queries.iter_mut().take(q) {
        let Some(value) = read_permutation(values, cursor, n) else { return -1; };
        *slot = value; cursor += n;
    }
    let required = 8 * (q + 1);
    if output.is_null() || capacity < required { return -2; }
    let mut layers = [Layer::default(); MAX_N];
    let id = identity(n);
    for level in 0..n {
        layers[level].in_orbit[level] = true;
        layers[level].orbit[0] = level;
        layers[level].orbit_count = 1;
        layers[level].transversal[level] = id;
    }
    if !build_chain(&mut layers, n, &generators, m) { return -1; }
    let mut order = 1i64;
    for layer in layers.iter().take(n) { order *= layer.orbit_count as i64; }
    unsafe { store_le(output, 0, order); }
    for i in 0..q { unsafe { store_le(output, 8 * (i + 1), is_member(&layers, queries[i], n) as i64); } }
    required as i64
}
