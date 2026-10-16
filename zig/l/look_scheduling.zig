const MAX_REQUESTS: usize = 4096;
const MAX_TRACK: usize = 256;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashI64(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    return result;
}

export fn look_scheduling(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 4 or length > MAX_REQUESTS + 4) return -1;
    const max_track64 = values[0];
    const start64 = values[1];
    const direction = values[2];
    const count64 = values[3];
    if (max_track64 < 1 or max_track64 > MAX_TRACK or start64 < 0 or start64 >= max_track64 or
        (direction != 0 and direction != 1) or count64 < 0 or count64 > MAX_REQUESTS or
        length != @as(usize, @intCast(count64)) + 4) return -1;
    const max_track: usize = @intCast(max_track64);
    const start: usize = @intCast(start64);
    const count: usize = @intCast(count64);
    var lower_counts: [MAX_TRACK]usize = [_]usize{0} ** MAX_TRACK;
    var upper_counts: [MAX_TRACK]usize = [_]usize{0} ** MAX_TRACK;
    var farthest: i64 = 0;
    for (0..count) |i| {
        const request = values[4 + i];
        if (request < -2147483648 or request > 2147483647) return -1;
        if (request >= 0 and request < max_track64) {
            const track: usize = @intCast(request);
            if (track < start) lower_counts[track] += 1 else upper_counts[track] += 1;
            if (request > farthest) farthest = request;
        }
    }

    var route: [MAX_REQUESTS]i64 = undefined;
    var route_count: usize = 0;
    if (direction == 1) {
        for (start..max_track) |track| {
            for (0..upper_counts[track]) |_| { route[route_count] = @intCast(track); route_count += 1; }
        }
        var track = start;
        while (track > 0) {
            track -= 1;
            for (0..lower_counts[track]) |_| { route[route_count] = @intCast(track); route_count += 1; }
        }
    } else {
        var track = start;
        while (track > 0) {
            track -= 1;
            for (0..lower_counts[track]) |_| { route[route_count] = @intCast(track); route_count += 1; }
        }
        for (start..max_track) |track_index| {
            for (0..upper_counts[track_index]) |_| { route[route_count] = @intCast(track_index); route_count += 1; }
        }
    }

    var hash = hashI64(FNV_OFFSET, @intCast(route_count));
    for (route[0..route_count]) |request| hash = hashI64(hash, request);
    const final_direction: i64 = if (direction == 1) 0 else 1;
    hash = hashI64(hash, final_direction);
    hash = hashI64(hash, farthest);
    hash = hashI64(hash, start64);
    return @intCast(hash & 0x7fffffffffffffff);
}
