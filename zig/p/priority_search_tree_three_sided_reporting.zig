// Clean-room McCreight radix priority-search-tree profile.
const MAX_N: usize = 8;
const MAX_Q: usize = 7;
const X_DOMAIN: usize = 32;

export fn priority_search_tree_three_sided_reporting(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 48) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const q64 = input[1];
    if (n64 < 0 or n64 > 8 or q64 < 0 or q64 > 7 or length != 2 + 3 * @as(usize, @intCast(n64)) + 3 * @as(usize, @intCast(q64))) return -1;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    var nx = [_]i64{0} ** MAX_N;
    var ny = [_]i64{0} ** MAX_N;
    var nl = [_]i64{0} ** MAX_N;
    var nlo = [_]i64{0} ** MAX_N;
    var nhi = [_]i64{0} ** MAX_N;
    var left = [_]i32{-1} ** MAX_N;
    var right = [_]i32{-1} ** MAX_N;
    var seen_x = [_]bool{false} ** X_DOMAIN;
    var seen_label = [_]bool{false} ** MAX_N;
    var root: i32 = -1;
    var count: usize = 0;
    var at: usize = 2;
    for (0..n) |_| {
        const x = input[at]; const y = input[at + 1]; const label = input[at + 2]; at += 3;
        if (x < 0 or x >= 32 or y < -64 or y > 63 or label < 0 or label >= 8) return -1;
        const xi: usize = @intCast(x); const li: usize = @intCast(label);
        if (seen_x[xi] or seen_label[li]) return -1;
        seen_x[xi] = true; seen_label[li] = true;
        var px = x; var py = y; var pl = label;
        if (root < 0) {
            root = @intCast(count); count += 1;
            const r: usize = @intCast(root);
            nx[r] = px; ny[r] = py; nl[r] = pl; nlo[r] = 0; nhi[r] = 32;
        } else {
            var cur: usize = @intCast(root);
            var low: usize = 0; var high: usize = X_DOMAIN;
            while (true) {
                if (py < ny[cur]) {
                    const tx = nx[cur]; nx[cur] = px; px = tx;
                    const ty = ny[cur]; ny[cur] = py; py = ty;
                    const tl = nl[cur]; nl[cur] = pl; pl = tl;
                }
                const mid = (low + high) / 2;
                if (px < @as(i64, @intCast(mid))) {
                    if (left[cur] < 0) {
                        const child = count; count += 1; left[cur] = @intCast(child);
                        nx[child] = px; ny[child] = py; nl[child] = pl;
                        nlo[child] = @intCast(low); nhi[child] = @intCast(mid); break;
                    }
                    cur = @intCast(left[cur]); high = mid;
                } else {
                    if (right[cur] < 0) {
                        const child = count; count += 1; right[cur] = @intCast(child);
                        nx[child] = px; ny[child] = py; nl[child] = pl;
                        nlo[child] = @intCast(mid); nhi[child] = @intCast(high); break;
                    }
                    cur = @intCast(right[cur]); low = mid;
                }
            }
        }
    }
    var qx0 = [_]i64{0} ** MAX_Q; var qx1 = [_]i64{0} ** MAX_Q; var qy1 = [_]i64{0} ** MAX_Q;
    for (0..q) |qi| {
        const x0 = input[at]; const x1 = input[at + 1]; const y1 = input[at + 2]; at += 3;
        if (x0 < 0 or x0 > x1 or x1 >= 32 or y1 < -64 or y1 > 63) return -1;
        qx0[qi] = x0; qx1[qi] = x1; qy1[qi] = y1;
    }
    var result: i64 = 0;
    for (0..q) |qi| {
        var mask: i64 = 0;
        if (root >= 0) {
            var stack = [_]usize{0} ** MAX_N;
            var top: usize = 1; stack[0] = @intCast(root);
            while (top > 0) {
                top -= 1;
                const node = stack[top];
                if (qx1[qi] < nlo[node] or qx0[qi] >= nhi[node] or ny[node] > qy1[qi]) continue;
                if (qx0[qi] <= nx[node] and nx[node] <= qx1[qi]) mask |= @as(i64, 1) << @as(u6, @intCast(nl[node]));
                if (left[node] >= 0) { stack[top] = @intCast(left[node]); top += 1; }
                if (right[node] >= 0) { stack[top] = @intCast(right[node]); top += 1; }
            }
        }
        result |= mask << @as(u6, @intCast(8 * qi));
    }
    return result;
}
