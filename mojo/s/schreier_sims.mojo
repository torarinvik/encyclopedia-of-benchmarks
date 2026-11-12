from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime SCH_MAX_N = 6
comptime SCH_MAX_GENERATORS = 4
comptime SCH_MAX_QUERIES = 8
comptime SCH_MAX_INPUT = 76
comptime SCH_MAX_STRONG_GENERATORS = 32
comptime SCH_MAX_PENDING = 8192
comptime SCH_GENERATOR_COUNTS = SCH_MAX_N * SCH_MAX_STRONG_GENERATORS
comptime SCH_ORBIT_FLAGS = SCH_GENERATOR_COUNTS + SCH_MAX_N
comptime SCH_ORBITS = SCH_ORBIT_FLAGS + SCH_MAX_N * SCH_MAX_N
comptime SCH_ORBIT_COUNTS = SCH_ORBITS + SCH_MAX_N * SCH_MAX_N
comptime SCH_TRANSVERSALS = SCH_ORBIT_COUNTS + SCH_MAX_N
comptime SCH_STATE_SIZE = SCH_TRANSVERSALS + SCH_MAX_N * SCH_MAX_N

fn sch_identity(n: Int) -> Int64:
    var result: Int64 = 0
    var place: Int64 = 1
    for point in range(n):
        result += Int64(point + 1) * place
        place *= 7
    return result

fn sch_encode(images: InlineArray[Int, SCH_MAX_N], n: Int) -> Int64:
    var result: Int64 = 0
    var place: Int64 = 1
    for point in range(n):
        result += Int64(images[point] + 1) * place
        place *= 7
    return result

fn sch_image_of(value_input: Int64, point_input: Int) -> Int:
    var value = value_input
    var point = point_input
    while point > 0:
        value //= 7
        point -= 1
    return Int(value % 7) - 1

fn sch_compose(first: Int64, second: Int64, n: Int) -> Int64:
    var images = InlineArray[Int, SCH_MAX_N]()
    for point in range(n): images[point] = sch_image_of(second, sch_image_of(first, point))
    return sch_encode(images, n)

fn sch_inverse(value: Int64, n: Int) -> Int64:
    var images = InlineArray[Int, SCH_MAX_N]()
    for point in range(n): images[sch_image_of(value, point)] = point
    return sch_encode(images, n)

fn sch_append_generator(inout state: InlineArray[Int64, SCH_STATE_SIZE], level: Int, value: Int64) -> Bool:
    var count = Int(state[SCH_GENERATOR_COUNTS + level])
    for i in range(count):
        if state[level * SCH_MAX_STRONG_GENERATORS + i] == value: return True
    if count >= SCH_MAX_STRONG_GENERATORS: return False
    state[level * SCH_MAX_STRONG_GENERATORS + count] = value
    state[SCH_GENERATOR_COUNTS + level] = Int64(count + 1)
    return True

fn sch_rebuild_orbit(inout state: InlineArray[Int64, SCH_STATE_SIZE], level: Int, n: Int, id: Int64):
    for point in range(n): state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + point] = 0
    state[SCH_ORBIT_COUNTS + level] = 1
    state[SCH_ORBITS + level * SCH_MAX_N] = Int64(level)
    state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + level] = 1
    state[SCH_TRANSVERSALS + level * SCH_MAX_N + level] = id
    var at = 0
    while at < Int(state[SCH_ORBIT_COUNTS + level]):
        let point = Int(state[SCH_ORBITS + level * SCH_MAX_N + at])
        at += 1
        let representative = state[SCH_TRANSVERSALS + level * SCH_MAX_N + point]
        let generator_count = Int(state[SCH_GENERATOR_COUNTS + level])
        for g in range(generator_count):
            let generator = state[level * SCH_MAX_STRONG_GENERATORS + g]
            let image = sch_image_of(generator, point)
            if state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + image] == 0:
                state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + image] = 1
                state[SCH_TRANSVERSALS + level * SCH_MAX_N + image] = sch_compose(representative, generator, n)
                let count = Int(state[SCH_ORBIT_COUNTS + level])
                state[SCH_ORBITS + level * SCH_MAX_N + count] = Int64(image)
                state[SCH_ORBIT_COUNTS + level] = Int64(count + 1)

fn sch_sift(state: InlineArray[Int64, SCH_STATE_SIZE], start: Int, value_input: Int64, n: Int,
            inout pair: InlineArray[Int64, 2]) -> Int:
    var residue = value_input
    var level = start
    while level < n:
        let image = sch_image_of(residue, level)
        if state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + image] == 0: break
        let representative = state[SCH_TRANSVERSALS + level * SCH_MAX_N + image]
        residue = sch_compose(residue, sch_inverse(representative, n), n)
        level += 1
    pair[0] = residue
    pair[1] = Int64(level)
    return level

fn sch_build_chain(inout state: InlineArray[Int64, SCH_STATE_SIZE],
                   inout pending: InlineArray[Int64, 2 * SCH_MAX_PENDING],
                   generators: InlineArray[Int64, SCH_MAX_GENERATORS], count: Int, n: Int) -> Bool:
    let id = sch_identity(n)
    var head = 0
    var tail = 0
    for i in range(count):
        pending[2 * tail] = 0
        pending[2 * tail + 1] = generators[i]
        tail += 1
    while head < tail:
        let start = Int(pending[2 * head])
        let candidate = pending[2 * head + 1]
        head += 1
        var pair = InlineArray[Int64, 2]()
        let level = sch_sift(state, start, candidate, n, pair)
        let residue = pair[0]
        if residue == id or level == n: continue
        let inverse_residue = sch_inverse(residue, n)
        if not sch_append_generator(state, level, residue) or not sch_append_generator(state, level, inverse_residue):
            return False
        sch_rebuild_orbit(state, level, n, id)
        if level + 1 < n:
            let orbit_count = Int(state[SCH_ORBIT_COUNTS + level])
            let generator_count = Int(state[SCH_GENERATOR_COUNTS + level])
            for orbit_index in range(orbit_count):
                let point = Int(state[SCH_ORBITS + level * SCH_MAX_N + orbit_index])
                let representative = state[SCH_TRANSVERSALS + level * SCH_MAX_N + point]
                for g in range(generator_count):
                    let generator = state[level * SCH_MAX_STRONG_GENERATORS + g]
                    let image = sch_image_of(generator, point)
                    let other = state[SCH_TRANSVERSALS + level * SCH_MAX_N + image]
                    let schreier = sch_compose(sch_compose(representative, generator, n), sch_inverse(other, n), n)
                    if schreier != id:
                        if tail >= SCH_MAX_PENDING: return False
                        pending[2 * tail] = Int64(level + 1)
                        pending[2 * tail + 1] = schreier
                        tail += 1
    return True

fn sch_is_member(state: InlineArray[Int64, SCH_STATE_SIZE], value_input: Int64, n: Int) -> Bool:
    var residue = value_input
    let id = sch_identity(n)
    for level in range(n):
        let image = sch_image_of(residue, level)
        if state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + image] == 0: return False
        let representative = state[SCH_TRANSVERSALS + level * SCH_MAX_N + image]
        residue = sch_compose(residue, sch_inverse(representative, n), n)
    return residue == id

fn sch_read_permutation(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int, n: Int) -> Int64:
    var used = InlineArray[Bool, SCH_MAX_N]()
    var images = InlineArray[Int, SCH_MAX_N]()
    for point in range(n):
        let image = input[offset + point]
        if image < 0 or image >= n or used[Int(image)]: return -1
        used[Int(image)] = True
        images[point] = Int(image)
    return sch_encode(images, n)

fn sch_store_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("schreier_sims")
fn schreier_sims(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > SCH_MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    let q_value = input[2]
    if n_value < 1 or n_value > SCH_MAX_N or m_value < 0 or m_value > SCH_MAX_GENERATORS or
        q_value < 1 or q_value > SCH_MAX_QUERIES: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let q = Int(q_value)
    if Int(length) != 3 + n * (m + q): return -1
    var generators = InlineArray[Int64, SCH_MAX_GENERATORS]()
    var queries = InlineArray[Int64, SCH_MAX_QUERIES]()
    var cursor = 3
    for i in range(m):
        generators[i] = sch_read_permutation(input, cursor, n)
        if generators[i] < 0: return -1
        cursor += n
    for i in range(q):
        queries[i] = sch_read_permutation(input, cursor, n)
        if queries[i] < 0: return -1
        cursor += n
    let required = 8 * (q + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required: return -2

    var state = InlineArray[Int64, SCH_STATE_SIZE]()
    let id = sch_identity(n)
    for level in range(n):
        state[SCH_ORBIT_FLAGS + level * SCH_MAX_N + level] = 1
        state[SCH_ORBITS + level * SCH_MAX_N] = Int64(level)
        state[SCH_ORBIT_COUNTS + level] = 1
        state[SCH_TRANSVERSALS + level * SCH_MAX_N + level] = id
    var pending = InlineArray[Int64, 2 * SCH_MAX_PENDING]()
    if not sch_build_chain(state, pending, generators, m, n): return -1
    var order: Int64 = 1
    for level in range(n): order *= state[SCH_ORBIT_COUNTS + level]
    sch_store_le(order, output, 0)
    for i in range(q):
        var membership: Int64 = 0
        if sch_is_member(state, queries[i], n): membership = 1
        sch_store_le(membership, output, 8 * (i + 1))
    return Int64(required)
