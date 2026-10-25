const MAX_MODULES: usize = 8;
const MAX_NETS: usize = 16;
const MAX_INPUT: usize = 146;
const Nets = [MAX_NETS][MAX_MODULES]usize;
const Degrees = [MAX_NETS]usize;

fn edgeCut(side: [MAX_MODULES]i32, nets: Nets, degrees: Degrees, net_count: usize) i32 {
    var total: i32 = 0;
    for (0..net_count) |net| {
        for (0..degrees[net]) |i| {
            for (i + 1..degrees[net]) |j| {
                if (side[nets[net][i]] != side[nets[net][j]]) total += 1;
            }
        }
    }
    return total;
}

fn netCut(side: [MAX_MODULES]i32, nets: Nets, degrees: Degrees, net_count: usize) i32 {
    var total: i32 = 0;
    for (0..net_count) |net| {
        const first = side[nets[net][0]];
        for (1..degrees[net]) |i| {
            if (side[nets[net][i]] != first) { total += 1; break; }
        }
    }
    return total;
}

export fn ptrdist_ks(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const module_value = input[0];
    const net_value = input[1];
    if (module_value < 2 or module_value > 8 or @mod(module_value, 2) != 0 or net_value < 0 or net_value > 16) return -1;
    const modules: usize = @intCast(module_value);
    const net_count: usize = @intCast(net_value);
    var nets: Nets = undefined;
    var degrees = [_]usize{0} ** MAX_NETS;
    var cursor: usize = 2;
    for (0..net_count) |net| {
        if (cursor >= length) return -1;
        const degree_value = input[cursor];
        cursor += 1;
        if (degree_value < 2 or degree_value > module_value or cursor + @as(usize, @intCast(degree_value)) > length) return -1;
        const degree: usize = @intCast(degree_value);
        degrees[net] = degree;
        for (0..degree) |i| {
            const member_value = input[cursor];
            cursor += 1;
            if (member_value < 0 or member_value >= module_value) return -1;
            const member: usize = @intCast(member_value);
            for (0..i) |j| {
                if (nets[net][j] == member) return -1;
            }
            nets[net][i] = member;
        }
    }
    if (cursor != length) return -1;

    const half = modules / 2;
    var order_a = [_]usize{0} ** MAX_MODULES;
    var order_b = [_]usize{0} ** MAX_MODULES;
    var side = [_]i32{0} ** MAX_MODULES;
    for (0..half) |i| {
        order_a[i] = i;
        order_b[i] = half + i;
        side[half + i] = 1;
    }
    var accepted_passes: i64 = 0;
    while (true) {
        var work = side;
        var remaining_a = order_a;
        var remaining_b = order_b;
        var selected_a = [_]usize{0} ** MAX_MODULES;
        var selected_b = [_]usize{0} ** MAX_MODULES;
        var count_a = half;
        var count_b = half;
        var cumulative_gain: i32 = 0;
        var best_gain: i32 = -2147483647;
        var best_prefix: usize = 0;
        for (0..half) |step| {
            const baseline = edgeCut(work, nets, degrees, net_count);
            var pair_gain: i32 = -2147483647;
            var chosen_a: usize = MAX_MODULES;
            var chosen_b: usize = MAX_MODULES;
            for (0..count_a) |ai| {
                const a = remaining_a[ai];
                for (0..count_b) |bi| {
                    const b = remaining_b[bi];
                    work[a] = 1;
                    work[b] = 0;
                    const gain = baseline - edgeCut(work, nets, degrees, net_count);
                    work[a] = 0;
                    work[b] = 1;
                    if (gain > pair_gain) {
                        pair_gain = gain;
                        chosen_a = a;
                        chosen_b = b;
                    }
                }
            }
            selected_a[step] = chosen_a;
            selected_b[step] = chosen_b;
            work[chosen_a] = 1;
            work[chosen_b] = 0;
            var i: usize = 0;
            while (i < count_a) : (i += 1) {
                if (remaining_a[i] == chosen_a) {
                    var j = i;
                    while (j + 1 < count_a) : (j += 1) remaining_a[j] = remaining_a[j + 1];
                    count_a -= 1;
                    break;
                }
            }
            i = 0;
            while (i < count_b) : (i += 1) {
                if (remaining_b[i] == chosen_b) {
                    var j = i;
                    while (j + 1 < count_b) : (j += 1) remaining_b[j] = remaining_b[j + 1];
                    count_b -= 1;
                    break;
                }
            }
            cumulative_gain += pair_gain;
            if (cumulative_gain > best_gain) {
                best_gain = cumulative_gain;
                best_prefix = step + 1;
            }
        }
        if (best_gain <= 0) break;
        var next_a = [_]usize{0} ** MAX_MODULES;
        var next_b = [_]usize{0} ** MAX_MODULES;
        for (0..best_prefix) |i| {
            next_a[i] = selected_b[i];
            next_b[i] = selected_a[i];
        }
        for (best_prefix..half) |i| {
            next_a[i] = selected_a[i];
            next_b[i] = selected_b[i];
        }
        order_a = next_a;
        order_b = next_b;
        for (0..half) |i| {
            side[order_a[i]] = 0;
            side[order_b[i]] = 1;
        }
        accepted_passes += 1;
    }
    var mask: i64 = 0;
    for (0..modules) |i| {
        if (side[i] == 0) mask |= @as(i64, 1) << @intCast(i);
    }
    return mask + (@as(i64, @intCast(edgeCut(side, nets, degrees, net_count))) << 8) +
        (@as(i64, @intCast(netCut(side, nets, degrees, net_count))) << 17) + (accepted_passes << 22);
}
