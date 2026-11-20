const FP_MAX_N: usize = 8;
const FP_MAX_SHAPES: usize = 512;
const FP_LAYER_WORDS: usize = FP_MAX_SHAPES * FP_MAX_N;

fn canonical(xs: [FP_MAX_N]i64, ys: [FP_MAX_N]i64, size: usize) [FP_MAX_N]i64 {
    var best: [FP_MAX_N]i64 = @splat(0);
    var have_best = false;
    for (0..8) |mode| {
        var tx: [FP_MAX_N]i64 = @splat(0);
        var ty: [FP_MAX_N]i64 = @splat(0);
        var codes: [FP_MAX_N]i64 = @splat(0);
        var min_x: i64 = 1000;
        var min_y: i64 = 1000;
        for (0..size) |i| {
            var a = if (mode >= 4) ys[i] else xs[i];
            var b = if (mode >= 4) xs[i] else ys[i];
            if ((mode & 1) != 0) a = -a;
            if ((mode & 2) != 0) b = -b;
            tx[i] = a;
            ty[i] = b;
            min_x = @min(min_x, a);
            min_y = @min(min_y, b);
        }
        for (0..size) |i| {
            codes[i] = (tx[i] - min_x) * 8 + ty[i] - min_y;
            var j = i;
            while (j > 0 and codes[j] < codes[j - 1]) : (j -= 1) {
                const temp = codes[j];
                codes[j] = codes[j - 1];
                codes[j - 1] = temp;
            }
        }
        var less = !have_best;
        if (have_best) {
            for (0..size) |i| {
                if (codes[i] != best[i]) {
                    less = codes[i] < best[i];
                    break;
                }
            }
        }
        if (less) {
            for (0..size) |i| best[i] = codes[i];
            have_best = true;
        }
    }
    return best;
}

export fn free_polyomino_enumeration(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > FP_MAX_N) return -1;
    const n: usize = @intCast(input[0]);
    var shapes: [2 * FP_LAYER_WORDS]i64 = @splat(0);
    var current: usize = 0;
    var shape_count: usize = 1;
    const dx = [_]i64{ 1, -1, 0, 0 };
    const dy = [_]i64{ 0, 0, 1, -1 };
    for (1..n) |size| {
        const next = 1 - current;
        var next_count: usize = 0;
        for (0..shape_count) |s| {
            for (0..size) |cell| {
                const code = shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + cell];
                const x = code / 8;
                const y = code % 8;
                for (0..4) |direction| {
                    const nx = x + dx[direction];
                    const ny = y + dy[direction];
                    var occupied = false;
                    if (nx >= 0 and nx < 8 and ny >= 0 and ny < 8) {
                        const neighbor = nx * 8 + ny;
                        for (0..size) |i| {
                            if (shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i] == neighbor) occupied = true;
                        }
                    }
                    if (occupied) continue;
                    var xs: [FP_MAX_N]i64 = @splat(0);
                    var ys: [FP_MAX_N]i64 = @splat(0);
                    for (0..size) |i| {
                        const previous = shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i];
                        xs[i] = previous / 8;
                        ys[i] = previous % 8;
                    }
                    xs[size] = nx;
                    ys[size] = ny;
                    const candidate = canonical(xs, ys, size + 1);
                    var duplicate = false;
                    for (0..next_count) |old| {
                        if (!duplicate) {
                            var same = true;
                            for (0..size + 1) |i| {
                                if (shapes[next * FP_LAYER_WORDS + old * FP_MAX_N + i] != candidate[i]) same = false;
                            }
                            if (same) duplicate = true;
                        }
                    }
                    if (!duplicate) {
                        if (next_count >= FP_MAX_SHAPES) return -1;
                        for (0..size + 1) |i| shapes[next * FP_LAYER_WORDS + next_count * FP_MAX_N + i] = candidate[i];
                        next_count += 1;
                    }
                }
            }
        }
        current = next;
        shape_count = next_count;
    }
    return @intCast(shape_count);
}
