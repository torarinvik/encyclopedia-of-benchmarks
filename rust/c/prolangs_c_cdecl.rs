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

#[derive(Clone, Copy)]
struct Op { kind: i32, value: i32, argc: usize, param_type: [i32; MAX_PARAMS], param_ptrs: [i32; MAX_PARAMS] }
impl Op { const EMPTY: Self = Self { kind: 0, value: 0, argc: 0, param_type: [0; MAX_PARAMS], param_ptrs: [0; MAX_PARAMS] }; }
struct Parser { input: [u8; MAX_INPUT], length: usize, pos: usize }

fn skip_space(p: &mut Parser) {
    while p.pos < p.length && matches!(p.input[p.pos], b' ' | b'\t' | b'\n' | b'\r') { p.pos += 1; }
}
fn peek(p: &mut Parser) -> i32 { skip_space(p); if p.pos < p.length { i32::from(p.input[p.pos]) } else { -1 } }
fn consume(p: &mut Parser, wanted: u8) -> bool { if peek(p) != i32::from(wanted) { return false; } p.pos += 1; true }
fn read_word(p: &mut Parser, out: &mut [u8; MAX_NAME + 1]) -> usize {
    let mut c = peek(p);
    if !(c >= 65 && c <= 90 || c >= 97 && c <= 122 || c == 95) { return 0; }
    let mut used = 0;
    while p.pos < p.length && { c = i32::from(p.input[p.pos]); c >= 0 && (c >= 65 && c <= 90 || c >= 97 && c <= 122 || c >= 48 && c <= 57 || c == 95) } {
        if used >= MAX_NAME { return 0; }
        out[used] = c as u8;
        used += 1; p.pos += 1; c = peek(p);
    }
    out[used] = 0;
    used
}
fn base_type(p: &mut Parser) -> i32 {
    let mut token = [0u8; MAX_NAME + 1];
    let n = read_word(p, &mut token);
    match &token[..n] {
        b"char" => TYPE_CHAR, b"int" => TYPE_INT, b"float" => TYPE_FLOAT,
        b"double" => TYPE_DOUBLE, b"void" => TYPE_VOID, _ => 0,
    }
}
fn decimal(p: &mut Parser) -> Option<i32> {
    let mut c = peek(p); if c < 48 || c > 57 { return None; }
    let mut result = 0;
    while p.pos < p.length && { c = i32::from(p.input[p.pos]); c >= 48 && c <= 57 } {
        result = result * 10 + c - 48; if result > 99 { return None; }
        p.pos += 1; c = peek(p);
    }
    if result < 1 { None } else { Some(result) }
}
fn append_op(ops: &mut [Op; MAX_OPS], count: &mut usize, item: Op) -> bool {
    if *count >= MAX_OPS { return false; }
    ops[*count] = item; *count += 1; true
}
fn parse_params(p: &mut Parser, item: &mut Op) -> bool {
    item.argc = 0;
    if !consume(p, b'(') { return false; }
    if consume(p, b')') { return true; }
    loop {
        if item.argc >= MAX_PARAMS { return false; }
        let typ = base_type(p); if typ == 0 { return false; }
        let mut stars = 0;
        while consume(p, b'*') { stars += 1; if stars > 8 { return false; } }
        item.param_type[item.argc] = typ; item.param_ptrs[item.argc] = stars; item.argc += 1;
        if consume(p, b')') { break; }
        if !consume(p, b',') { return false; }
    }
    if item.argc == 1 && item.param_type[0] == TYPE_VOID && item.param_ptrs[0] == 0 { item.argc = 0; }
    else { for a in 0..item.argc { if item.param_type[a] == TYPE_VOID && item.param_ptrs[a] == 0 { return false; } } }
    true
}
fn parse_declarator(p: &mut Parser, name: &mut [u8; MAX_NAME + 1], ops: &mut [Op; MAX_OPS], count: &mut usize, depth: usize) -> bool {
    if depth > MAX_DEPTH { return false; }
    let mut stars = 0;
    while consume(p, b'*') { stars += 1; if stars > 8 { return false; } }
    if consume(p, b'(') {
        if !parse_declarator(p, name, ops, count, depth + 1) || !consume(p, b')') { return false; }
    } else {
        if name[0] != 0 || read_word(p, name) == 0 { return false; }
    }
    loop {
        match peek(p) {
            91 => { let mut item = Op::EMPTY; item.kind = OP_ARRAY; if !consume(p, b'[') { return false; }
                let Some(dim) = decimal(p) else { return false; }; item.value = dim;
                if !consume(p, b']') || !append_op(ops, count, item) { return false; } }
            40 => { let mut item = Op::EMPTY; item.kind = OP_FUNCTION;
                if !parse_params(p, &mut item) || !append_op(ops, count, item) { return false; } }
            _ => break,
        }
    }
    while stars > 0 { let mut item = Op::EMPTY; item.kind = OP_POINTER; if !append_op(ops, count, item) { return false; } stars -= 1; }
    true
}
fn valid_order(base: i32, ops: &[Op; MAX_OPS], count: usize) -> bool {
    let mut current = 0; let mut is_void = base == TYPE_VOID;
    for i in (0..count).rev() {
        match ops[i].kind {
            OP_ARRAY => { if current == 3 || current == 0 && is_void { return false; } current = 2; is_void = false; }
            OP_FUNCTION => { if current == 2 || current == 3 { return false; } current = 3; is_void = false; }
            OP_POINTER => { current = 1; is_void = false; }
            _ => return false,
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn prolangs_c_cdecl(input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT { return -1; }
    let mut source = [0u8; MAX_INPUT];
    for i in 0..input_length { let value = *input.add(i); if value <= 0 || value > 127 { return -1; } source[i] = value as u8; }
    let mut p = Parser { input: source, length: input_length, pos: 0 };
    let base = base_type(&mut p); let mut name = [0u8; MAX_NAME + 1]; let mut ops = [Op::EMPTY; MAX_OPS]; let mut count = 0;
    if base == 0 || !parse_declarator(&mut p, &mut name, &mut ops, &mut count, 0) || !valid_order(base, &ops, count) || (base == TYPE_VOID && count == 0) || peek(&mut p) != -1 { return -1; }
    let mut name_length = 0; while name_length < MAX_NAME && name[name_length] != 0 { name_length += 1; }
    if matches!(&name[..name_length], b"char" | b"int" | b"float" | b"double" | b"void") { return -1; }
    let mut encoded = [0u8; MAX_OUTPUT]; let mut used = 0;
    encoded[used] = base as u8; used += 1; encoded[used] = name_length as u8; used += 1;
    for c in &name[..name_length] { encoded[used] = *c; used += 1; }
    encoded[used] = count as u8; used += 1;
    for op in &ops[..count] {
        encoded[used] = op.kind as u8; used += 1;
        if op.kind == OP_ARRAY { encoded[used] = op.value as u8; used += 1; }
        else if op.kind == OP_FUNCTION { encoded[used] = op.argc as u8; used += 1;
            for a in 0..op.argc { encoded[used] = op.param_type[a] as u8; used += 1; encoded[used] = op.param_ptrs[a] as u8; used += 1; }
        }
    }
    if output.is_null() || output_capacity < used { return -2; }
    std::ptr::copy_nonoverlapping(encoded.as_ptr(), output, used);
    used as i64
}
