// Clean-room bounded declarator parser; no upstream source text is copied.
module main

const max_input = 96
const max_name = 16
const max_ops = 12
const max_depth = 6
const max_params = 3
const max_output = 128
const op_pointer = 1
const op_array = 2
const op_function = 3
const type_char = 1
const type_int = 2
const type_float = 3
const type_double = 4
const type_void = 5

struct Op { mut: kind int; value int; argc int; param_type [3]int; param_ptrs [3]int }
struct Parser { input &i64; length int; mut: pos int }

fn skip_space(mut p Parser) {
    for p.pos < p.length {
        c := unsafe { p.input[p.pos] }
        if c != 32 && c != 9 && c != 10 && c != 13 { break }
        p.pos++
    }
}
fn peek(mut p Parser) int {
    skip_space(mut p)
    if p.pos < p.length { return int(unsafe { p.input[p.pos] }) }
    return -1
}
fn consume(mut p Parser, wanted int) bool {
    if peek(mut p) != wanted { return false }
    p.pos++
    return true
}
fn is_word_start(c int) bool { return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 }
fn is_word_part(c int) bool { return is_word_start(c) || (c >= 48 && c <= 57) }
fn read_word(mut p Parser, mut out [17]u8) int {
    mut c := peek(mut p)
    if !is_word_start(c) { return 0 }
    mut used := 0
    for p.pos < p.length && is_word_part(int(unsafe { p.input[p.pos] })) {
        c = int(unsafe { p.input[p.pos] })
        if used >= max_name { return 0 }
        out[used] = u8(c); used++; p.pos++; c = peek(mut p)
    }
    out[used] = 0
    return used
}
fn word_is(token [17]u8, length int, expected string) bool {
    if length != expected.len { return false }
    for i in 0..length { if token[i] != expected[i] { return false } }
    return true
}
fn base_type(mut p Parser) int {
    mut token := [17]u8{}
    n := read_word(mut p, mut token)
    if word_is(token,n,"char") { return type_char }
    if word_is(token,n,"int") { return type_int }
    if word_is(token,n,"float") { return type_float }
    if word_is(token,n,"double") { return type_double }
    if word_is(token,n,"void") { return type_void }
    return 0
}
fn decimal(mut p Parser, mut value int) bool {
    mut c := peek(mut p)
    if c < 48 || c > 57 { return false }
    mut result := 0
    for p.pos < p.length && int(unsafe { p.input[p.pos] }) >= 48 && int(unsafe { p.input[p.pos] }) <= 57 {
        c = int(unsafe { p.input[p.pos] })
        result = result * 10 + c - 48
        if result > 99 { return false }
        p.pos++; c = peek(mut p)
    }
    if result < 1 { return false }
    value = result
    return true
}
fn append_op(mut ops [max_ops]Op, mut count int, item Op) bool {
    if count >= max_ops { return false }
    ops[count] = item; count++
    return true
}
fn parse_params(mut p Parser, mut item Op) bool {
    item.argc = 0
    if !consume(mut p,40) { return false }
    if consume(mut p,41) { return true }
    for {
        if item.argc >= max_params { return false }
        typ := base_type(mut p)
        if typ == 0 { return false }
        mut stars := 0
        for consume(mut p,42) { stars++; if stars > 8 { return false } }
        item.param_type[item.argc] = typ; item.param_ptrs[item.argc] = stars; item.argc++
        if consume(mut p,41) { break }
        if !consume(mut p,44) { return false }
    }
    if item.argc == 1 && item.param_type[0] == type_void && item.param_ptrs[0] == 0 { item.argc = 0 }
    else { for a in 0..item.argc { if item.param_type[a] == type_void && item.param_ptrs[a] == 0 { return false } } }
    return true
}
fn parse_declarator(mut p Parser, mut name [17]u8, mut ops [max_ops]Op, mut count int, depth int) bool {
    if depth > max_depth { return false }
    mut stars := 0
    for consume(mut p,42) { stars++; if stars > 8 { return false } }
    if consume(mut p,40) {
        if !parse_declarator(mut p,mut name,mut ops,mut count,depth+1) || !consume(mut p,41) { return false }
    } else if name[0] != 0 || read_word(mut p,mut name) == 0 { return false }
    for {
        c := peek(mut p)
        if c == 91 {
            mut item := Op{kind:op_array}
            if !consume(mut p,91) || !decimal(mut p,mut item.value) || !consume(mut p,93) || !append_op(mut ops,mut count,item) { return false }
        } else if c == 40 {
            mut item := Op{kind:op_function}
            if !parse_params(mut p,mut item) || !append_op(mut ops,mut count,item) { return false }
        } else { break }
    }
    for stars > 0 { if !append_op(mut ops,mut count,Op{kind:op_pointer}) { return false }; stars-- }
    return true
}
fn valid_order(base int, ops [max_ops]Op, count int) bool {
    mut current := 0
    mut is_void := base == type_void
    mut i := count
    for i > 0 {
        i--
        if ops[i].kind == op_array {
            if current == 3 || (current == 0 && is_void) { return false }
            current = 2; is_void = false
        } else if ops[i].kind == op_function {
            if current == 2 || current == 3 { return false }
            current = 3; is_void = false
        } else if ops[i].kind == op_pointer { current = 1; is_void = false }
        else { return false }
    }
    return true
}

@[export: 'prolangs_c_cdecl']
pub fn prolangs_c_cdecl(input &i64,input_length usize,output &u8,output_capacity usize) i64 {
    if unsafe { input == nil } || input_length < 1 || input_length > usize(max_input) { return -1 }
    for i in 0..int(input_length) { value := unsafe { input[i] }; if value <= 0 || value > 127 { return -1 } }
    mut p := Parser{input:input,length:int(input_length)}
    base := base_type(mut p)
    mut name := [17]u8{}
    mut ops := [max_ops]Op{}
    mut count := 0
    if base == 0 || !parse_declarator(mut p,mut name,mut ops,mut count,0) || !valid_order(base,ops,count) || (base == type_void && count == 0) || peek(mut p) != -1 { return -1 }
    mut name_len := 0
    for name_len < max_name && name[name_len] != 0 { name_len++ }
    if word_is(name,name_len,"char") || word_is(name,name_len,"int") || word_is(name,name_len,"float") || word_is(name,name_len,"double") || word_is(name,name_len,"void") { return -1 }
    mut encoded := [max_output]u8{}
    mut used := 0
    encoded[used]=u8(base);used++;encoded[used]=u8(name_len);used++
    for i in 0..name_len { encoded[used]=name[i];used++ }
    encoded[used]=u8(count);used++
    for i in 0..count {
        encoded[used]=u8(ops[i].kind);used++
        if ops[i].kind==op_array {encoded[used]=u8(ops[i].value);used++}
        else if ops[i].kind==op_function {encoded[used]=u8(ops[i].argc);used++;for a in 0..ops[i].argc{encoded[used]=u8(ops[i].param_type[a]);used++;encoded[used]=u8(ops[i].param_ptrs[a]);used++}}
    }
    if unsafe { output == nil } || output_capacity < usize(used) { return -2 }
    unsafe { for i in 0..used { output[i]=encoded[i] } }
    return i64(used)
}
