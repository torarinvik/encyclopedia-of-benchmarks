const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const MAX_STATES: usize = 2 * MAX_PATTERN + 2;
const ROOT: usize = 0;
const ARTIFICIAL: usize = 1;

const Automaton = struct {
    transition: [MAX_STATES][4]i64,
    displacement: [MAX_STATES][4]i64,
    suffix_link: [MAX_STATES]i64,
    max_length: [MAX_STATES]i64,
    position: [MAX_STATES]i64,
    terminal: [MAX_STATES]i64,
    state_count: usize,

    fn init(self: *Automaton) void {
        self.state_count = 2;
        for (0..MAX_STATES) |state| {
            self.suffix_link[state] = -1;
            self.max_length[state] = 0;
            self.position[state] = 0;
            self.terminal[state] = 0;
            for (0..4) |symbol| {
                self.transition[state][symbol] = -1;
                self.displacement[state][symbol] = 0;
            }
        }
        self.suffix_link[ROOT] = @intCast(ARTIFICIAL);
    }

    fn build(self: *Automaton, pattern: *const [MAX_PATTERN]i64, m: usize) bool {
        var last = ROOT;
        for (0..m) |offset| {
            const symbol: usize = @intCast(pattern[m - 1 - offset]);
            if (self.state_count >= MAX_STATES) return false;
            const current = self.state_count;
            self.state_count += 1;
            self.max_length[current] = self.max_length[last] + 1;
            self.position[current] = self.position[last] + 1;
            var state: i64 = @intCast(last);
            while (state != @as(i64, @intCast(ROOT)) and self.transition[@intCast(state)][symbol] < 0) {
                self.transition[@intCast(state)][symbol] = @intCast(current);
                self.displacement[@intCast(state)][symbol] =
                    self.position[current] - self.position[@intCast(state)] - 1;
                state = self.suffix_link[@intCast(state)];
            }
            const target = self.transition[@intCast(state)][symbol];
            if (target < 0) {
                self.transition[ROOT][symbol] = @intCast(current);
                self.displacement[ROOT][symbol] = self.position[current] - self.position[ROOT] - 1;
                self.suffix_link[current] = @intCast(ROOT);
            } else if (self.max_length[@intCast(state)] + 1 == self.max_length[@intCast(target)]) {
                self.suffix_link[current] = target;
            } else {
                if (self.state_count >= MAX_STATES) return false;
                const clone = self.state_count;
                self.state_count += 1;
                self.transition[clone] = self.transition[@intCast(target)];
                self.displacement[clone] = self.displacement[@intCast(target)];
                self.suffix_link[clone] = self.suffix_link[@intCast(target)];
                self.max_length[clone] = self.max_length[@intCast(state)] + 1;
                self.position[clone] = self.position[@intCast(target)];
                self.terminal[clone] = self.terminal[@intCast(target)];
                self.suffix_link[@intCast(target)] = @intCast(clone);
                self.suffix_link[current] = @intCast(clone);
                while (state != @as(i64, @intCast(ARTIFICIAL))) {
                    const old_target = self.transition[@intCast(state)][symbol];
                    if (old_target < 0 or self.max_length[@intCast(old_target)] < self.max_length[clone]) break;
                    self.displacement[@intCast(state)][symbol] =
                        self.position[@intCast(old_target)] - self.position[@intCast(state)] - 1;
                    self.transition[@intCast(state)][symbol] = @intCast(clone);
                    state = self.suffix_link[@intCast(state)];
                }
            }
            last = current;
        }
        self.terminal[last] = 1;
        while (last != ROOT) {
            last = @intCast(self.suffix_link[last]);
            self.terminal[last] = 1;
        }
        return true;
    }
};

fn mpNext(pattern: *const [MAX_PATTERN]i64, m: usize,
          next: *[MAX_PATTERN + 1]i64) void {
    var i: i64 = 0;
    var border: i64 = -1;
    next[0] = -1;
    while (@as(usize, @intCast(i)) < m) {
        while (border >= 0 and pattern[@intCast(i)] != pattern[@intCast(border)])
            border = next[@intCast(border)];
        i += 1;
        border += 1;
        next[@intCast(i)] = border;
    }
}

fn search(aut: *const Automaton, text: []const i64, m: usize,
          mp: *const [MAX_PATTERN + 1]i64) i64 {
    if (text.len < m) return 0;
    const period: i64 = @as(i64, @intCast(m)) - mp[m];
    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    var start: usize = 0;
    var preceding_shift: i64 = @intCast(m);
    while (start <= text.len - m) {
        var index: i64 = @as(i64, @intCast(m)) - 1;
        var state: usize = ROOT;
        var boundary: i64 = @as(i64, @intCast(m)) - 1 - preceding_shift;
        const prefix_length = @as(i64, @intCast(m)) - preceding_shift;
        const prefix_period: i64 = if (preceding_shift != @as(i64, @intCast(m)))
            prefix_length - mp[@intCast(prefix_length)] else 0;
        var shift: i64 = @intCast(m);
        var displacement_sum: i64 = 0;
        while (index > boundary) {
            const symbol: usize = @intCast(text[start + @as(usize, @intCast(index))]);
            const target = aut.transition[state][symbol];
            if (target < 0) break;
            displacement_sum += aut.displacement[state][symbol];
            state = @intCast(target);
            if (aut.terminal[state] != 0) shift = index;
            index -= 1;
        }
        if (index <= boundary) {
            if (displacement_sum == 0) {
                count += 1;
                offset_sum += @intCast(start);
                offset_xor ^= @intCast(start);
                shift = period;
            } else {
                const half = @divTrunc(boundary + 1, 2);
                if (prefix_period <= half) {
                    boundary -= prefix_period;
                    while (index > boundary) {
                        const symbol: usize = @intCast(text[start + @as(usize, @intCast(index))]);
                        const target = aut.transition[state][symbol];
                        if (target < 0) break;
                        displacement_sum += aut.displacement[state][symbol];
                        state = @intCast(target);
                        if (aut.terminal[state] != 0) shift = index;
                        index -= 1;
                    }
                    if (index <= boundary) shift = displacement_sum;
                } else {
                    boundary = boundary - half - 1;
                    while (index > boundary) {
                        const symbol: usize = @intCast(text[start + @as(usize, @intCast(index))]);
                        const target = aut.transition[state][symbol];
                        if (target < 0) break;
                        displacement_sum += aut.displacement[state][symbol];
                        state = @intCast(target);
                        if (aut.terminal[state] != 0) shift = index;
                        index -= 1;
                    }
                }
            }
        }
        if (shift <= 0) return -1;
        start += @intCast(shift);
        preceding_shift = shift;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

export fn turbo_reverse_factor_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 0 or n_value > @as(i64, @intCast(MAX_TEXT)) or
        m_value < 1 or m_value > @as(i64, @intCast(MAX_PATTERN))) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |index| {
        if (input[2 + index] < 0 or input[2 + index] > 3) return -1;
    }
    var pattern = [_]i64{0} ** MAX_PATTERN;
    for (0..m) |index| pattern[index] = input[2 + n + index];
    var aut: Automaton = undefined;
    aut.init();
    if (!aut.build(&pattern, m)) return -1;
    var mp = [_]i64{0} ** (MAX_PATTERN + 1);
    mpNext(&pattern, m, &mp);
    return search(&aut, input[2 .. 2 + n], m, &mp);
}
