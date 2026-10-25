package prolangs_c_cdecl

import "core:c"

// Clean-room bounded declarator parser; no upstream source text is copied.
MAX_INPUT :: 96
MAX_NAME :: 16
MAX_OPS :: 12
MAX_DEPTH :: 6
MAX_PARAMS :: 3
MAX_OUTPUT :: 128
OP_POINTER :: 1
OP_ARRAY :: 2
OP_FUNCTION :: 3
TYPE_CHAR :: 1
TYPE_INT :: 2
TYPE_FLOAT :: 3
TYPE_DOUBLE :: 4
TYPE_VOID :: 5

Op :: struct { kind, value, argc: int; param_type, param_ptrs: [3]int }
Parser :: struct { input: [^]i64; length, pos: int }

skip_space :: proc(p: ^Parser) {
    for p.pos < p.length {
        ch := p.input[p.pos]
        if ch != 32 && ch != 9 && ch != 10 && ch != 13 do break
        p.pos += 1
    }
}
peek :: proc(p: ^Parser) -> int {
    skip_space(p)
    if p.pos < p.length do return int(p.input[p.pos])
    return -1
}
consume :: proc(p: ^Parser, wanted: int) -> bool {
    if peek(p) != wanted do return false
    p.pos += 1
    return true
}
word_start :: proc(ch: int) -> bool { return (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || ch == 95 }
word_part :: proc(ch: int) -> bool { return word_start(ch) || (ch >= 48 && ch <= 57) }
read_word :: proc(p: ^Parser, out: ^[17]u8) -> int {
    ch := peek(p)
    if !word_start(ch) do return 0
    used := 0
    for p.pos < p.length && word_part(int(p.input[p.pos])) {
        ch = int(p.input[p.pos])
        if used >= MAX_NAME do return 0
        out[used] = u8(ch); used += 1; p.pos += 1; ch = peek(p)
    }
    out[used] = 0
    return used
}
word_is :: proc(token: [17]u8, n: int, expected: string) -> bool {
    if n != len(expected) do return false
    for i := 0; i < n; i += 1 { if token[i] != expected[i] do return false }
    return true
}
base_type :: proc(p: ^Parser) -> int {
    token: [17]u8 = {}
    n := read_word(p, &token)
    if word_is(token,n,"char") do return TYPE_CHAR
    if word_is(token,n,"int") do return TYPE_INT
    if word_is(token,n,"float") do return TYPE_FLOAT
    if word_is(token,n,"double") do return TYPE_DOUBLE
    if word_is(token,n,"void") do return TYPE_VOID
    return 0
}
decimal :: proc(p: ^Parser, value: ^int) -> bool {
    ch := peek(p)
    if ch < 48 || ch > 57 do return false
    result := 0
    for p.pos < p.length && int(p.input[p.pos]) >= 48 && int(p.input[p.pos]) <= 57 {
        ch = int(p.input[p.pos])
        result = result * 10 + ch - 48
        if result > 99 do return false
        p.pos += 1; ch = peek(p)
    }
    if result < 1 do return false
    value^ = result
    return true
}
append_op :: proc(ops: ^[MAX_OPS]Op, count: ^int, item: Op) -> bool {
    if count^ >= MAX_OPS do return false
    ops[count^] = item; count^ += 1
    return true
}
parse_params :: proc(p: ^Parser, item: ^Op) -> bool {
    item.argc = 0
    if !consume(p,40) do return false
    if consume(p,41) do return true
    for {
        if item.argc >= MAX_PARAMS do return false
        typ := base_type(p)
        if typ == 0 do return false
        stars := 0
        for consume(p,42) { stars += 1; if stars > 8 do return false }
        item.param_type[item.argc] = typ; item.param_ptrs[item.argc] = stars; item.argc += 1
        if consume(p,41) do break
        if !consume(p,44) do return false
    }
    if item.argc == 1 && item.param_type[0] == TYPE_VOID && item.param_ptrs[0] == 0 do item.argc = 0
    else for a := 0; a < item.argc; a += 1 { if item.param_type[a] == TYPE_VOID && item.param_ptrs[a] == 0 do return false }
    return true
}
parse_declarator :: proc(p: ^Parser, name: ^[17]u8, ops: ^[MAX_OPS]Op, count: ^int, depth: int) -> bool {
    if depth > MAX_DEPTH do return false
    stars := 0
    for consume(p,42) { stars += 1; if stars > 8 do return false }
    if consume(p,40) {
        if !parse_declarator(p,name,ops,count,depth+1) || !consume(p,41) do return false
    } else if name[0] != 0 || read_word(p,name) == 0 do return false
    for {
        ch := peek(p)
        if ch == 91 {
            item := Op{kind=OP_ARRAY}
            if !consume(p,91) || !decimal(p,&item.value) || !consume(p,93) || !append_op(ops,count,item) do return false
        } else if ch == 40 {
            item := Op{kind=OP_FUNCTION}
            if !parse_params(p,&item) || !append_op(ops,count,item) do return false
        } else do break
    }
    for stars > 0 { if !append_op(ops,count,Op{kind=OP_POINTER}) do return false; stars -= 1 }
    return true
}
valid_order :: proc(base: int, ops: ^[MAX_OPS]Op, count: int) -> bool {
    current := 0
    is_void := base == TYPE_VOID
    i := count
    for i > 0 {
        i -= 1
        if ops[i].kind == OP_ARRAY {
            if current == 3 || current == 0 && is_void do return false
            current = 2; is_void = false
        } else if ops[i].kind == OP_FUNCTION {
            if current == 2 || current == 3 do return false
            current = 3; is_void = false
        } else if ops[i].kind == OP_POINTER { current = 1; is_void = false }
        else do return false
    }
    return true
}

@(export)
prolangs_c_cdecl :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 1 || input_length > c.size_t(MAX_INPUT) do return -1
    for i := 0; i < int(input_length); i += 1 { if input[i] <= 0 || input[i] > 127 do return -1 }
    p := Parser{input=input,length=int(input_length)}
    base := base_type(&p)
    name: [17]u8 = {}
    ops: [MAX_OPS]Op = {}
    count := 0
    if base == 0 || !parse_declarator(&p,&name,&ops,&count,0) || !valid_order(base,&ops,count) || (base == TYPE_VOID && count == 0) || peek(&p) != -1 do return -1
    name_len := 0
    for name_len < MAX_NAME && name[name_len] != 0 { name_len += 1 }
    if word_is(name,name_len,"char") || word_is(name,name_len,"int") || word_is(name,name_len,"float") || word_is(name,name_len,"double") || word_is(name,name_len,"void") do return -1
    encoded: [MAX_OUTPUT]u8 = {}
    used := 0
    encoded[used]=u8(base);used+=1;encoded[used]=u8(name_len);used+=1
    for i := 0; i < name_len; i += 1 { encoded[used]=name[i];used+=1 }
    encoded[used]=u8(count);used+=1
    for i := 0; i < count; i += 1 {
        encoded[used]=u8(ops[i].kind);used+=1
        if ops[i].kind==OP_ARRAY {encoded[used]=u8(ops[i].value);used+=1}
        else if ops[i].kind==OP_FUNCTION {encoded[used]=u8(ops[i].argc);used+=1;for a:=0;a<ops[i].argc;a+=1{encoded[used]=u8(ops[i].param_type[a]);used+=1;encoded[used]=u8(ops[i].param_ptrs[a]);used+=1}}
    }
    if output==nil || output_capacity<c.size_t(used) do return -2
    for i:=0;i<used;i+=1 {output[i]=encoded[i]}
    return i64(used)
}
