const std = @import("std");
const Parser = struct {
    tokens: []const i64,
    cursor: usize = 0,
    valid: bool = true,
    fn parse(self: *Parser, depth: i64, nested: bool) i64 {
        if (depth > 16) { self.valid = false; return 0; }
        var total: i64 = 0;
        while (self.cursor < self.tokens.len) {
            const x = self.tokens[self.cursor]; self.cursor += 1;
            if (x == 2002) { if (!nested) self.valid = false; return total * depth; }
            if (x == 2001) total += self.parse(depth + 1, true)
            else if (x >= -1000 and x <= 1000) total += x
            else { self.valid = false; return 0; }
            if (!self.valid) return 0;
        }
        if (nested) self.valid = false;
        return total * depth;
    }
};
export fn product_sum(v: [*c]const i64, n: usize) i64 {
    if (v == null or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    var p = Parser{ .tokens = v[1..n] };
    const result = p.parse(1, false);
    return if (p.valid and p.cursor == p.tokens.len) result else -1;
}
