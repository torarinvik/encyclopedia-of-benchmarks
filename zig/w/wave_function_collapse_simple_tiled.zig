const MAX_CELLS: usize = 16;
const MAX_TILES: usize = 4;
const MAX_COMPATIBILITY: usize = 4 * MAX_TILES;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 56;

fn propagate(
    domains: *[MAX_CELLS]u8,
    compatibility: *const [MAX_COMPATIBILITY]u8,
    width: usize,
    height: usize,
    tile_count: usize,
    start_cell: usize,
    seed_all: bool,
) bool {
    const cell_count = width * height;
    var queue: [MAX_CELLS]usize = @splat(0);
    var in_queue: [MAX_CELLS]bool = @splat(false);
    var head: usize = 0;
    var tail: usize = 0;
    var queued: usize = 0;
    if (seed_all) {
        for (0..cell_count) |cell| {
            queue[tail] = cell;
            tail = (tail + 1) % cell_count;
            queued += 1;
            in_queue[cell] = true;
        }
    } else {
        queue[tail] = start_cell;
        tail = (tail + 1) % cell_count;
        queued += 1;
        in_queue[start_cell] = true;
    }

    while (queued != 0) {
        const source = queue[head];
        head = (head + 1) % cell_count;
        queued -= 1;
        in_queue[source] = false;
        const row = source / width;
        const column = source % width;
        for (0..4) |direction| {
            var neighbor: usize = 0;
            var has_neighbor = false;
            if (direction == 0 and row != 0) {
                neighbor = source - width;
                has_neighbor = true;
            } else if (direction == 1 and column + 1 < width) {
                neighbor = source + 1;
                has_neighbor = true;
            } else if (direction == 2 and row + 1 < height) {
                neighbor = source + width;
                has_neighbor = true;
            } else if (direction == 3 and column != 0) {
                neighbor = source - 1;
                has_neighbor = true;
            }
            if (!has_neighbor) continue;
            var supported: u8 = 0;
            for (0..tile_count) |tile| {
                const bit: u8 = @as(u8, 1) << @intCast(tile);
                if (domains[source] & bit != 0) supported |= compatibility[direction * tile_count + tile];
            }
            const reduced = domains[neighbor] & supported;
            if (reduced == domains[neighbor]) continue;
            domains[neighbor] = reduced;
            if (reduced == 0) return false;
            if (!in_queue[neighbor]) {
                queue[tail] = neighbor;
                tail = (tail + 1) % cell_count;
                queued += 1;
                in_queue[neighbor] = true;
            }
        }
    }
    return true;
}

export fn wave_function_collapse_simple_tiled(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 4 or input[2] < 1 or input[2] > 4) return -1;
    const width: usize = @intCast(input[0]);
    const height: usize = @intCast(input[1]);
    const tile_count: usize = @intCast(input[2]);
    const cell_count = width * height;
    if (length != 3 + 2 * cell_count + 5 * tile_count) return -1;
    const full_mask: u8 = @intCast((@as(u16, 1) << @intCast(tile_count)) - 1);
    var domains: [MAX_CELLS]u8 = @splat(0);
    var weights: [MAX_TILES]u8 = @splat(0);
    var compatibility: [MAX_COMPATIBILITY]u8 = @splat(0);
    var draws: [MAX_CELLS]u16 = @splat(0);
    var position: usize = 3;
    for (0..cell_count) |cell| {
        const value = input[position];
        if (value < 1 or value > @as(i64, full_mask)) return -1;
        domains[cell] = @intCast(value);
        position += 1;
    }
    for (0..tile_count) |tile| {
        const value = input[position];
        if (value < 1 or value > 4) return -1;
        weights[tile] = @intCast(value);
        position += 1;
    }
    for (0..4) |direction| {
        for (0..tile_count) |tile| {
            const value = input[position];
            if (value < 0 or value > @as(i64, full_mask)) return -1;
            compatibility[direction * tile_count + tile] = @intCast(value);
            position += 1;
        }
    }
    for (0..cell_count) |cell| {
        const value = input[position];
        if (value < 0 or value > 65535) return -1;
        draws[cell] = @intCast(value);
        position += 1;
    }

    for (0..tile_count) |first| {
        for (0..tile_count) |second| {
            const north = compatibility[first] & (@as(u8, 1) << @intCast(second)) != 0;
            const south_reverse = compatibility[2 * tile_count + second] & (@as(u8, 1) << @intCast(first)) != 0;
            const east = compatibility[tile_count + first] & (@as(u8, 1) << @intCast(second)) != 0;
            const west_reverse = compatibility[3 * tile_count + second] & (@as(u8, 1) << @intCast(first)) != 0;
            if (north != south_reverse or east != west_reverse) return -1;
        }
    }

    if (!propagate(&domains, &compatibility, width, height, tile_count, 0, true)) return -2;
    while (true) {
        var best_cell = cell_count;
        var best_count: u32 = MAX_TILES + 1;
        for (0..cell_count) |cell| {
            const count: u32 = @as(u32, @popCount(domains[cell]));
            if (count > 1 and count < best_count) {
                best_cell = cell;
                best_count = count;
            }
        }
        if (best_cell == cell_count) break;
        var total_weight: u32 = 0;
        for (0..tile_count) |tile| {
            if (domains[best_cell] & (@as(u8, 1) << @intCast(tile)) != 0) total_weight += @as(u32, weights[tile]);
        }
        var rank = @as(u32, draws[best_cell]) * total_weight / 65536;
        var selected = tile_count;
        for (0..tile_count) |tile| {
            if (domains[best_cell] & (@as(u8, 1) << @intCast(tile)) == 0) continue;
            if (rank < @as(u32, weights[tile])) {
                selected = tile;
                break;
            }
            rank -= @as(u32, weights[tile]);
        }
        if (selected == tile_count) return -2;
        domains[best_cell] = @as(u8, 1) << @intCast(selected);
        if (!propagate(&domains, &compatibility, width, height, tile_count, best_cell, false)) return -2;
    }
    var result: i64 = @as(i64, 1) << 32;
    for (0..cell_count) |cell| {
        const tile: usize = @intCast(@ctz(domains[cell]));
        result |= @as(i64, @intCast(tile)) << @intCast(2 * cell);
    }
    return result;
}
