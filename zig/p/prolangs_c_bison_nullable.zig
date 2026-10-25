// Part of the Bison parser generator,
// Copyright (C) 1984 Bob Corbett and Free Software Foundation, Inc.
//
// BISON is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY. No author or distributor accepts responsibility to anyone
// for the consequences of using it or for whether it serves any
// particular purpose or works at all, unless he says so in writing.
// Refer to the BISON General Public License for full details.
//
// Everyone is granted permission to copy, modify and redistribute BISON,
// but only under the conditions described in the BISON General Public
// License. A copy of this license is supposed to have been given to you
// along with BISON so you can know your rights and responsibilities. It
// should be in a file named COPYING. Among other things, the copyright
// notice and this notice must be preserved on all copies.
//
// In other words, you are welcome to use, share and improve this program.
// You are forbidden to forbid anyone else to use, share and improve
// what you give them. Help stamp out software-hoarding!
//
// Modified 2026: bounded numeric grammar adapter; no upstream code is copied.
const MAX_NONTERMINALS: usize = 16;
const MAX_TERMINALS: usize = 16;
const MAX_RULES: usize = 32;
const MAX_RHS: usize = 8;
const MAX_RHS_ITEMS: usize = MAX_RULES * MAX_RHS;
const MAX_INPUT_LENGTH: usize = 3 + MAX_RULES * (2 + MAX_RHS);

export fn prolangs_c_bison_nullable(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 5 or length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_NONTERMINALS)) or
        values[1] < 0 or values[1] > @as(i64, @intCast(MAX_TERMINALS)) or
        values[2] < 1 or values[2] > @as(i64, @intCast(MAX_RULES))) return -1;
    const nonterminal_count: usize = @intCast(values[0]);
    const terminal_count: usize = @intCast(values[1]);
    const rule_count: usize = @intCast(values[2]);
    var lhs: [MAX_RULES]usize = @splat(0);
    var rhs_start: [MAX_RULES]usize = @splat(0);
    var rhs_length: [MAX_RULES]usize = @splat(0);
    var remaining: [MAX_RULES]usize = @splat(0);
    var rhs: [MAX_RHS_ITEMS]usize = @splat(0);
    var eligible: [MAX_RULES]bool = @splat(false);
    var nullable: [MAX_NONTERMINALS]bool = @splat(false);
    var symbol_queue: [MAX_NONTERMINALS]usize = @splat(0);
    var rhs_items: usize = 0;
    var offset: usize = 3;

    for (0..rule_count) |rule| {
        if (offset + 2 > length) return -1;
        if (values[offset] < 0 or values[offset] >= @as(i64, @intCast(nonterminal_count)) or
            values[offset + 1] < 0 or values[offset + 1] > @as(i64, @intCast(MAX_RHS))) return -1;
        lhs[rule] = @intCast(values[offset]);
        rhs_length[rule] = @intCast(values[offset + 1]);
        offset += 2;
        rhs_start[rule] = rhs_items;
        if (offset + rhs_length[rule] > length or rhs_items + rhs_length[rule] > MAX_RHS_ITEMS) return -1;
        var has_terminal = false;
        for (0..rhs_length[rule]) |_| {
            const symbol = values[offset];
            offset += 1;
            if (symbol < 0 or symbol >= @as(i64, @intCast(nonterminal_count + terminal_count))) return -1;
            rhs[rhs_items] = @intCast(symbol);
            rhs_items += 1;
            if (@as(usize, @intCast(symbol)) >= nonterminal_count) has_terminal = true;
        }
        if (rhs_length[rule] > 0 and !has_terminal) {
            eligible[rule] = true;
            remaining[rule] = rhs_length[rule];
        }
    }
    if (offset != length) return -1;

    var queue_tail: usize = 0;
    for (0..rule_count) |rule| {
        if (rhs_length[rule] == 0 and !nullable[lhs[rule]]) {
            nullable[lhs[rule]] = true;
            symbol_queue[queue_tail] = lhs[rule];
            queue_tail += 1;
        }
    }
    var queue_head: usize = 0;
    while (queue_head < queue_tail) {
        const symbol = symbol_queue[queue_head];
        queue_head += 1;
        for (0..rule_count) |rule| {
            if (!eligible[rule]) continue;
            for (0..rhs_length[rule]) |j| {
                if (rhs[rhs_start[rule] + j] == symbol) {
                    remaining[rule] -= 1;
                    if (remaining[rule] == 0 and !nullable[lhs[rule]]) {
                        nullable[lhs[rule]] = true;
                        symbol_queue[queue_tail] = lhs[rule];
                        queue_tail += 1;
                    }
                }
            }
        }
    }
    var mask: i64 = 0;
    var bit: i64 = 1;
    for (0..nonterminal_count) |symbol| {
        if (nullable[symbol]) mask += bit;
        bit *= 2;
    }
    return mask;
}
