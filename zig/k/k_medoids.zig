const INVALID_RESULT: i64 = -1;
const MAX_PACKED_LENGTH: usize = 16;

fn distanceI64(a: i64, b: i64) i64 { return if (a >= b) a - b else b - a; }

export fn k_medoids(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 3 or length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const point_count = values[0];
    const medoid_count = values[1];
    const max_iter = values[2];
    if (point_count < 2 or point_count > 8 or medoid_count < 1 or medoid_count > 4 or medoid_count > point_count or
        max_iter < 1 or max_iter > 16 or length != @as(usize, @intCast(3 + point_count + medoid_count))) return INVALID_RESULT;
    const n: usize = @intCast(point_count);
    const k: usize = @intCast(medoid_count);
    var medoids = [_]i64{0} ** 4;
    var points = [_]i64{0} ** 8;
    var labels = [_]i64{0} ** 8;
    for (0..k) |slot| {
        medoids[slot] = values[3 + slot];
        if (medoids[slot] < 0 or medoids[slot] >= point_count) return INVALID_RESULT;
        for (0..slot) |earlier| if (medoids[earlier] == medoids[slot]) return INVALID_RESULT;
    }
    for (0..n) |i| {
        points[i] = values[3 + k + i];
        if (points[i] < -16 or points[i] > 16) return INVALID_RESULT;
        for (0..i) |earlier| if (points[earlier] == points[i]) return INVALID_RESULT;
    }

    for (0..@as(usize, @intCast(max_iter))) |_| {
        for (0..n) |i| {
            var best_slot: usize = 0;
            var best_distance = distanceI64(points[i], points[@intCast(medoids[0])]);
            for (1..k) |slot| {
                const distance = distanceI64(points[i], points[@intCast(medoids[slot])]);
                if (distance < best_distance) { best_distance = distance; best_slot = slot; }
            }
            labels[i] = @intCast(best_slot);
        }

        var updated = [_]i64{0} ** 4;
        for (0..k) |slot| {
            var first = n;
            for (0..n) |i| { if (labels[i] == @as(i64, @intCast(slot))) { first = i; break; } }
            if (first == n) return INVALID_RESULT;
            var best_index = first;
            var best_cost: i64 = 0;
            for (0..n) |i| { if (labels[i] == @as(i64, @intCast(slot))) best_cost += distanceI64(points[first], points[i]); }
            for (first + 1..n) |candidate| {
                if (labels[candidate] != @as(i64, @intCast(slot))) continue;
                var cost: i64 = 0;
                for (0..n) |i| { if (labels[i] == @as(i64, @intCast(slot))) cost += distanceI64(points[candidate], points[i]); }
                if (cost < best_cost) { best_cost = cost; best_index = candidate; }
            }
            updated[slot] = @intCast(best_index);
        }
        var changed = false;
        for (0..k) |slot| if (updated[slot] != medoids[slot]) { changed = true; };
        if (!changed) break;
        medoids = updated;
    }

    var result: i64 = 0;
    for (0..k) |slot| result |= medoids[slot] << @as(u6, @intCast(3 * slot));
    for (0..n) |i| result |= labels[i] << @as(u6, @intCast(12 + 2 * i));
    return result;
}
