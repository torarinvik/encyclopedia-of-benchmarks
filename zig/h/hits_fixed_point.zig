const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 131;
const MAX_PARSEABLE: usize = 132;
const SCALE: i64 = 1_000_000;

export fn hits_fixed_point(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > MAX_PARSEABLE) return -1;
    const n_value = input[0];
    const m_value = input[1];
    const k_value = input[2];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    if (m_value < 0 or m_value > @as(i64, @intCast(MAX_M))) return -1;
    if (k_value < 0 or k_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const k: usize = @intCast(k_value);
    if (length != 3 + 2 * m or length > MAX_INPUT) return -1;

    var arc_from: [MAX_M]usize = @splat(0);
    var arc_to: [MAX_M]usize = @splat(0);
    for (0..m) |arc| {
        const u_value = input[3 + 2 * arc];
        const v_value = input[4 + 2 * arc];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value) return -1;
        arc_from[arc] = @intCast(u_value);
        arc_to[arc] = @intCast(v_value);
        for (0..arc) |previous| {
            if (arc_from[previous] == arc_from[arc] and arc_to[previous] == arc_to[arc]) return -1;
        }
    }

    var authority: [MAX_N]i64 = @splat(0);
    var hub: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| hub[vertex] = SCALE;
    for (0..k) |_| {
        var raw: [MAX_N]i64 = @splat(0);
        for (0..m) |arc| raw[arc_to[arc]] += hub[arc_from[arc]];
        var authority_total: i64 = 0;
        for (0..n) |vertex| authority_total += raw[vertex];
        for (0..n) |vertex| {
            if (authority_total == 0) authority[vertex] = 0
            else authority[vertex] = raw[vertex] * SCALE / authority_total;
        }

        for (0..n) |vertex| raw[vertex] = 0;
        for (0..m) |arc| raw[arc_from[arc]] += authority[arc_to[arc]];
        var hub_total: i64 = 0;
        for (0..n) |vertex| hub_total += raw[vertex];
        for (0..n) |vertex| {
            if (hub_total == 0) hub[vertex] = 0
            else hub[vertex] = raw[vertex] * SCALE / hub_total;
        }
    }

    var checksum: i64 = 0;
    for (0..n) |vertex| {
        checksum += @as(i64, @intCast(vertex + 1)) * (authority[vertex] + 65537 * hub[vertex]);
    }
    return checksum;
}
