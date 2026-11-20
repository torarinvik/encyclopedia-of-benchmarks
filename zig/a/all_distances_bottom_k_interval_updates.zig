const MAX_N: usize = 32;
const MAX_K: i64 = 4;
const MAX_INPUT: usize = 99;
const MAX_WORDS: usize = 97;
const DISTANCE_LIMIT: i64 = 1_000_000;
const END_SENTINEL: i64 = 1_000_001;

const Interval = struct { item_id: i64 = 0, rank: i64 = 0, first: i64 = 0, past: i64 = 0 };

fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[8 * word + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn all_distances_bottom_k_interval_updates(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const n0 = input[0];
    const k0 = input[1];
    if (n0 < 2 or n0 > MAX_N or k0 < 2 or k0 > MAX_K or k0 > n0) return -1;
    const n: usize = @intCast(n0);
    const k: usize = @intCast(k0);
    if (length != 2 + 3 * n) return -1;

    var records = [_]Interval{.{}} ** MAX_N;
    var seen_id = [_]bool{false} ** MAX_N;
    var seen_rank = [_]bool{false} ** MAX_N;
    for (0..n) |i| {
        const id = input[2 + 3 * i];
        const distance = input[3 + 3 * i];
        const rank = input[4 + 3 * i];
        if (id < 0 or id >= n0 or seen_id[@intCast(id)] or rank < 0 or rank >= n0
            or seen_rank[@intCast(rank)] or distance < 0 or distance > DISTANCE_LIMIT) return -1;
        seen_id[@intCast(id)] = true;
        seen_rank[@intCast(rank)] = true;
        for (0..i) |j| if (records[j].first == distance) return -1;
        records[i] = .{ .item_id = id, .rank = rank, .first = distance, .past = 0 };
    }
    for (1..k) |i| if (records[i - 1].first >= records[i].first) return -1;
    for (k..n) |i| if (records[i].first <= records[k - 1].first) return -1;

    var intervals = [_]Interval{.{}} ** MAX_N;
    var count = k;
    for (0..k) |i| intervals[i] = .{ .item_id = records[i].item_id, .rank = records[i].rank,
        .first = records[i].first, .past = END_SENTINEL };
    for (k..n) |i| {
        var worst: usize = MAX_N;
        var active: usize = 0;
        for (0..count) |j| {
            if (intervals[j].first <= records[i].first and records[i].first < intervals[j].past) {
                active += 1;
                if (worst == MAX_N or intervals[j].rank > intervals[worst].rank) worst = j;
            }
        }
        if (active != k or worst == MAX_N) return -1;
        if (records[i].rank >= intervals[worst].rank) continue;
        var cursor = intervals[worst].past;
        intervals[worst].past = records[i].first;
        while (cursor < END_SENTINEL) {
            var next_worst: usize = MAX_N;
            for (0..count) |j| {
                if (intervals[j].first <= cursor and cursor < intervals[j].past
                    and (next_worst == MAX_N or intervals[j].rank > intervals[next_worst].rank))
                    next_worst = j;
            }
            if (next_worst == MAX_N or intervals[next_worst].rank <= records[i].rank) break;
            const next_cursor = intervals[next_worst].past;
            intervals[next_worst].past = cursor;
            cursor = next_cursor;
        }
        intervals[count] = .{ .item_id = records[i].item_id, .rank = records[i].rank,
            .first = records[i].first, .past = cursor };
        count += 1;
    }

    var order = [_]usize{0} ** MAX_N;
    var out_count: usize = 0;
    for (0..count) |i| if (intervals[i].first < intervals[i].past) {
        order[out_count] = i;
        out_count += 1;
    };
    for (1..out_count) |i| {
        const key = order[i];
        var j = i;
        while (j > 0 and (intervals[order[j - 1]].first > intervals[key].first
            or (intervals[order[j - 1]].first == intervals[key].first
                and intervals[order[j - 1]].item_id > intervals[key].item_id))) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }
    var staged = [_]i64{0} ** MAX_WORDS;
    staged[0] = @intCast(out_count);
    for (0..out_count) |i| {
        const x = intervals[order[i]];
        staged[1 + 3 * i] = x.item_id;
        staged[2 + 3 * i] = x.first;
        staged[3 + 3 * i] = x.past;
    }
    const words = 1 + 3 * out_count;
    const bytes = 8 * words;
    if (output == null or capacity < bytes) return -2;
    for (0..words) |word| putI64(output, word, staged[word]);
    return @intCast(bytes);
}
