const Matrix = struct {
    prefix: [11][65]usize = @splat(@splat(0)),
    zeros: [11]usize = @splat(0),

    fn less(self: *const Matrix, first: usize, last: usize, key: usize) usize {
        var left = first;
        var right = last;
        var result: usize = 0;
        for (0..11) |level| {
            const zl = self.prefix[level][left];
            const zr = self.prefix[level][right];
            if (key & (@as(usize, 1) << @as(u6, @intCast(10 - level))) != 0) {
                result += zr - zl;
                left = self.zeros[level] + left - zl;
                right = self.zeros[level] + right - zr;
            } else { left = zl; right = zr; }
        }
        return result;
    }

    fn quantile(self: *const Matrix, first: usize, last: usize, rank: usize) i64 {
        var left = first;
        var right = last;
        var k = rank;
        var key: usize = 0;
        for (0..11) |level| {
            const zl = self.prefix[level][left];
            const zr = self.prefix[level][right];
            if (k < zr - zl) { left = zl; right = zr; }
            else {
                k -= zr - zl;
                key |= @as(usize, 1) << @as(u6, @intCast(10 - level));
                left = self.zeros[level] + left - zl;
                right = self.zeros[level] + right - zr;
            }
        }
        return @as(i64, @intCast(key)) - 1000;
    }
};

pub export fn wavelet_matrix(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 706 or input[0] < 1 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length < n + 2) return -1;
    for (0..n) |i| { if (input[1+i] < -1000 or input[1+i] > 1000) return -1; }
    const qv = input[n+1];
    if (qv < 0 or qv > 128) return -1;
    const q: usize = @intCast(qv);
    if (length != n + 2 + 5*q) return -1;
    var matrix = Matrix{};
    var current: [64]usize = @splat(0);
    var scratch: [64]usize = @splat(0);
    for (0..n) |i| current[i] = @intCast(input[1+i] + 1000);
    for (0..11) |level| {
        const bit: u6 = @intCast(10-level);
        for (0..n) |i| {
            matrix.prefix[level][i+1] = matrix.prefix[level][i] + @intFromBool(current[i] & (@as(usize, 1) << bit) == 0);
        }
        const zeros = matrix.prefix[level][n];
        matrix.zeros[level] = zeros;
        var z: usize = 0;
        var o = zeros;
        for (0..n) |i| {
            if (current[i] & (@as(usize, 1) << bit) == 0) { scratch[z] = current[i]; z += 1; }
            else { scratch[o] = current[i]; o += 1; }
        }
        for (0..n) |i| current[i] = scratch[i];
    }
    var total: i64 = 0;
    for (0..q) |j| {
        const at = n+2+5*j;
        const op = input[at]; const a = input[at+1]; const b = input[at+2];
        const c = input[at+3]; const d = input[at+4];
        var answer: i64 = 0;
        if (op == 0) {
            if (a < -1000 or a > 1000 or b < -1 or b >= @as(i64, @intCast(n))) return -1;
            const right: usize = @intCast(b+1);
            answer = @intCast(matrix.less(0, right, @intCast(a+1001)) - matrix.less(0, right, @intCast(a+1000)));
        } else if (op == 1) {
            if (a < 0 or a > b or b >= @as(i64, @intCast(n)) or c < 0 or c > b-a) return -1;
            answer = matrix.quantile(@intCast(a), @intCast(b+1), @intCast(c));
        } else if (op == 2) {
            if (a < 0 or a > b or b >= @as(i64, @intCast(n)) or c < -1000 or c > d or d > 1000) return -1;
            answer = @intCast(matrix.less(@intCast(a), @intCast(b+1), @intCast(d+1001)) - matrix.less(@intCast(a), @intCast(b+1), @intCast(c+1000)));
        } else return -1;
        total += @as(i64, @intCast(j+1)) * (answer+1000001);
    }
    return total;
}
