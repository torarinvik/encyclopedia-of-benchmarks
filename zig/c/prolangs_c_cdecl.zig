// Clean-room bounded declarator parser; no upstream source text is copied.
const MAX_INPUT: usize = 96;
const MAX_NAME: usize = 16;
const MAX_OPS: usize = 12;
const MAX_DEPTH: usize = 6;
const MAX_PARAMS: usize = 3;
const MAX_OUTPUT: usize = 128;
const OP_POINTER: i32 = 1;
const OP_ARRAY: i32 = 2;
const OP_FUNCTION: i32 = 3;
const TYPE_CHAR: i32 = 1;
const TYPE_INT: i32 = 2;
const TYPE_FLOAT: i32 = 3;
const TYPE_DOUBLE: i32 = 4;
const TYPE_VOID: i32 = 5;

const Op = struct { kind: i32 = 0, value: i32 = 0, argc: usize = 0, param_type: [MAX_PARAMS]i32 = .{0,0,0}, param_ptrs: [MAX_PARAMS]i32 = .{0,0,0} };
const Parser = struct { input: [*c]const i64, length: usize, pos: usize = 0 };

fn skipSpace(p: *Parser) void {
    while (p.pos < p.length) {
        const c = p.input[p.pos];
        if (c != ' ' and c != '\t' and c != '\n' and c != '\r') break;
        p.pos += 1;
    }
}
fn peek(p: *Parser) i32 { skipSpace(p); if (p.pos < p.length) return @intCast(p.input[p.pos]); return -1; }
fn consume(p: *Parser, wanted: u8) bool { if (peek(p) != wanted) return false; p.pos += 1; return true; }
fn word(p: *Parser, out: *[MAX_NAME + 1]u8) usize {
    var c = peek(p);
    if (!((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or c == '_')) return 0;
    var used: usize = 0;
    while (p.pos < p.length) {
        c = @intCast(p.input[p.pos]);
        if (!((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') or c == '_')) break;
        if (used >= MAX_NAME) return 0;
        out[used] = @intCast(c); used += 1; p.pos += 1; c = peek(p);
    }
    out[used] = 0;
    return used;
}
fn eqlWord(token: *const [MAX_NAME + 1]u8, len: usize, expected: []const u8) bool {
    if (len != expected.len) return false;
    for (0..len) |i| if (token[i] != expected[i]) return false;
    return true;
}
fn baseType(p: *Parser) i32 {
    var token = [_]u8{0} ** (MAX_NAME + 1);
    const n = word(p, &token);
    if (eqlWord(&token, n, "char")) return TYPE_CHAR;
    if (eqlWord(&token, n, "int")) return TYPE_INT;
    if (eqlWord(&token, n, "float")) return TYPE_FLOAT;
    if (eqlWord(&token, n, "double")) return TYPE_DOUBLE;
    if (eqlWord(&token, n, "void")) return TYPE_VOID;
    return 0;
}
fn decimal(p: *Parser, value: *i32) bool {
    var c = peek(p); if (c < '0' or c > '9') return false;
    var result: i32 = 0;
    while (p.pos < p.length) {
        c = @intCast(p.input[p.pos]);
        if (c < '0' or c > '9') break;
        result = result * 10 + c - '0'; if (result > 99) return false; p.pos += 1;
    }
    if (result < 1) return false; value.* = result; return true;
}
fn appendOp(ops: *[MAX_OPS]Op, count: *usize, item: Op) bool {
    if (count.* >= MAX_OPS) return false; ops[count.*] = item; count.* += 1; return true;
}
fn parseParams(p: *Parser, item: *Op) bool {
    item.argc = 0; if (!consume(p, '(')) return false; if (consume(p, ')')) return true;
    while (true) {
        if (item.argc >= MAX_PARAMS) return false;
        const typ = baseType(p); if (typ == 0) return false;
        var stars: i32 = 0; while (consume(p, '*')) { stars += 1; if (stars > 8) return false; }
        item.param_type[item.argc] = typ; item.param_ptrs[item.argc] = stars; item.argc += 1;
        if (consume(p, ')')) break; if (!consume(p, ',')) return false;
    }
    if (item.argc == 1 and item.param_type[0] == TYPE_VOID and item.param_ptrs[0] == 0) {
        item.argc = 0;
    } else {
        for (0..item.argc) |a| { if (item.param_type[a] == TYPE_VOID and item.param_ptrs[a] == 0) return false; }
    }
    return true;
}
fn parseDeclarator(p: *Parser, name: *[MAX_NAME + 1]u8, ops: *[MAX_OPS]Op, count: *usize, depth: usize) bool {
    if (depth > MAX_DEPTH) return false;
    var stars: i32 = 0; while (consume(p, '*')) { stars += 1; if (stars > 8) return false; }
    if (consume(p, '(')) { if (!parseDeclarator(p, name, ops, count, depth + 1) or !consume(p, ')')) return false; }
    else if (name[0] != 0 or word(p, name) == 0) return false;
    while (true) {
        const c = peek(p);
        if (c == '[') { var item = Op{ .kind = OP_ARRAY }; if (!consume(p, '[') or !decimal(p, &item.value) or !consume(p, ']') or !appendOp(ops, count, item)) return false; }
        else if (c == '(') { var item = Op{ .kind = OP_FUNCTION }; if (!parseParams(p, &item) or !appendOp(ops, count, item)) return false; }
        else break;
    }
    while (stars > 0) { if (!appendOp(ops, count, Op{ .kind = OP_POINTER })) return false; stars -= 1; }
    return true;
}
fn validOrder(base: i32, ops: *const [MAX_OPS]Op, count: usize) bool {
    var current: i32 = 0; var is_void = base == TYPE_VOID; var i = count;
    while (i > 0) { i -= 1; switch (ops[i].kind) {
        OP_ARRAY => { if (current == 3 or (current == 0 and is_void)) return false; current = 2; is_void = false; },
        OP_FUNCTION => { if (current == 2 or current == 3) return false; current = 3; is_void = false; },
        OP_POINTER => { current = 1; is_void = false; },
        else => return false,
    } }
    return true;
}

pub export fn prolangs_c_cdecl(input: [*c]const i64, input_length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_INPUT) return -1;
    var source = [_]i64{0} ** MAX_INPUT;
    for (0..input_length) |i| { if (input[i] <= 0 or input[i] > 127) return -1; source[i] = input[i]; }
    var p = Parser{ .input = &source, .length = input_length };
    const base = baseType(&p); var name = [_]u8{0} ** (MAX_NAME + 1); var ops = [_]Op{.{}} ** MAX_OPS; var count: usize = 0;
    if (base == 0 or !parseDeclarator(&p, &name, &ops, &count, 0) or !validOrder(base, &ops, count) or (base == TYPE_VOID and count == 0) or peek(&p) != -1) return -1;
    var name_len: usize = 0; while (name_len < MAX_NAME and name[name_len] != 0) : (name_len += 1) {}
    if (eqlWord(&name,name_len,"char") or eqlWord(&name,name_len,"int") or eqlWord(&name,name_len,"float") or eqlWord(&name,name_len,"double") or eqlWord(&name,name_len,"void")) return -1;
    var encoded = [_]u8{0} ** MAX_OUTPUT; var used: usize = 0;
    encoded[used] = @intCast(base); used += 1; encoded[used] = @intCast(name_len); used += 1;
    for (0..name_len) |i| { encoded[used] = name[i]; used += 1; }
    encoded[used] = @intCast(count); used += 1;
    for (0..count) |i| {
        encoded[used] = @intCast(ops[i].kind); used += 1;
        if (ops[i].kind == OP_ARRAY) { encoded[used] = @intCast(ops[i].value); used += 1; }
        else if (ops[i].kind == OP_FUNCTION) { encoded[used] = @intCast(ops[i].argc); used += 1;
            for (0..ops[i].argc) |a| { encoded[used] = @intCast(ops[i].param_type[a]); used += 1; encoded[used] = @intCast(ops[i].param_ptrs[a]); used += 1; }
        }
    }
    if (output == null or output_capacity < used) return -2;
    for (0..used) |i| output[i] = encoded[i];
    return @intCast(used);
}
