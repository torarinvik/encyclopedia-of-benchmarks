const MAX_RAYS: usize = 5;
const MAX_ROUNDS: usize = 32;
const MAX_INPUT: usize = 11;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn randomized_ray_search(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const rays_raw = input[0];
    const growth = input[1];
    const initial = input[2];
    if (rays_raw < 2 or rays_raw > @as(i64, MAX_RAYS) or growth < 2 or growth > 4 or
        initial < 1000 or initial >= growth * 1000 or length != @as(usize, @intCast(rays_raw)) + 5) return -1;
    const rays: usize = @intCast(rays_raw);
    var permutation: [MAX_RAYS]usize = @splat(0);
    var seen: [MAX_RAYS]bool = @splat(false);
    for (0..rays) |i| {
        const ray = input[3 + i];
        if (ray < 0 or ray >= rays_raw) return -1;
        const index: usize = @intCast(ray);
        if (seen[index]) return -1;
        seen[index] = true;
        permutation[i] = index;
    }
    const target = input[3 + rays];
    const target_distance = input[4 + rays];
    if (target < 0 or target >= rays_raw or target_distance < 1 or target_distance > 1000000000) return -1;
    var distance = initial;
    var total: i64 = 0;
    var attempts: i64 = 0;
    var found = false;
    for (0..MAX_ROUNDS) |round| {
        const ray = permutation[round % rays];
        attempts += 1;
        if (@as(i64, @intCast(ray)) == target and target_distance <= distance) {
            total += target_distance;
            found = true;
            break;
        }
        total += 2 * distance;
        distance *= growth;
    }
    if (!found) return -1;
    if (output_opt == null or capacity < 16) return -2;
    const output = output_opt.?;
    store_i64_le(output, 0, attempts);
    store_i64_le(output, 8, total);
    return 16;
}
