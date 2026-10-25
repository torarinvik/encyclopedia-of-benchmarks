/*
 * Clean-room bounded C declarator parser for the cdecl benchmark family.
 * This file contains no copied source text from lac-dcc/Benchmarks.
 */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_INPUT = 96, MAX_NAME = 16, MAX_OPS = 12, MAX_DEPTH = 6,
       MAX_PARAMS = 3, MAX_OUTPUT = 128 };
enum { OP_POINTER = 1, OP_ARRAY = 2, OP_FUNCTION = 3 };
enum { TYPE_CHAR = 1, TYPE_INT = 2, TYPE_FLOAT = 3, TYPE_DOUBLE = 4, TYPE_VOID = 5 };

typedef struct { int kind, value, argc, param_type[MAX_PARAMS], param_ptrs[MAX_PARAMS]; } Op;
typedef struct { const int64_t *input; size_t length, pos; } Parser;

static void skip_space(Parser *p) {
    while (p->pos < p->length) {
        int ch = (int)p->input[p->pos];
        if (ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r') break;
        ++p->pos;
    }
}
static int peek(Parser *p) {
    skip_space(p);
    return p->pos < p->length ? (int)p->input[p->pos] : -1;
}
static int consume(Parser *p, int expected) {
    if (peek(p) != expected) return 0;
    ++p->pos;
    return 1;
}
static int word(Parser *p, char *out, size_t capacity) {
    int ch = peek(p);
    if (!((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_')) return 0;
    size_t used = 0;
    while (p->pos < p->length && (ch = (int)p->input[p->pos]) >= 0 &&
           ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') ||
            (ch >= '0' && ch <= '9') || ch == '_')) {
        if (used + 1 >= capacity) return 0;
        out[used++] = (char)ch;
        ++p->pos;
    }
    out[used] = '\0';
    return 1;
}
static int base_type(Parser *p) {
    char token[MAX_NAME + 1];
    if (!word(p, token, sizeof token)) return 0;
    if (strcmp(token, "char") == 0) return TYPE_CHAR;
    if (strcmp(token, "int") == 0) return TYPE_INT;
    if (strcmp(token, "float") == 0) return TYPE_FLOAT;
    if (strcmp(token, "double") == 0) return TYPE_DOUBLE;
    if (strcmp(token, "void") == 0) return TYPE_VOID;
    return 0;
}
static int decimal(Parser *p, int *value) {
    int ch = peek(p);
    if (ch < '0' || ch > '9') return 0;
    int result = 0;
    while (p->pos < p->length && (ch = (int)p->input[p->pos]) >= '0' && ch <= '9') {
        result = result * 10 + (ch - '0');
        if (result > 99) return 0;
        ++p->pos;
    }
    if (result < 1) return 0;
    *value = result;
    return 1;
}
static int append_op(Op ops[MAX_OPS], int *count, Op item) {
    if (*count >= MAX_OPS) return 0;
    ops[(*count)++] = item;
    return 1;
}
static int parse_params(Parser *p, int *argc, int types[MAX_PARAMS], int ptrs[MAX_PARAMS]) {
    *argc = 0;
    if (!consume(p, '(')) return 0;
    if (consume(p, ')')) return 1;
    for (;;) {
        if (*argc >= MAX_PARAMS) return 0;
        int type = base_type(p), stars = 0;
        if (!type) return 0;
        while (consume(p, '*')) {
            if (++stars > 8) return 0;
        }
        types[*argc] = type;
        ptrs[*argc] = stars;
        ++*argc;
        if (consume(p, ')')) break;
        if (!consume(p, ',')) return 0;
    }
    if (*argc == 1 && types[0] == TYPE_VOID && ptrs[0] == 0) *argc = 0;
    else for (int i = 0; i < *argc; ++i) if (types[i] == TYPE_VOID && ptrs[i] == 0) return 0;
    return 1;
}
static int parse_declarator(Parser *p, char name[MAX_NAME + 1], Op ops[MAX_OPS],
                            int *op_count, int depth) {
    if (depth > MAX_DEPTH) return 0;
    int stars = 0;
    while (consume(p, '*')) {
        if (++stars > 8) return 0;
    }
    if (consume(p, '(')) {
        if (!parse_declarator(p, name, ops, op_count, depth + 1) || !consume(p, ')')) return 0;
    } else {
        if (name[0] != '\0' || !word(p, name, MAX_NAME + 1)) return 0;
    }
    for (;;) {
        int ch = peek(p);
        if (ch == '[') {
            Op item = {0};
            item.kind = OP_ARRAY;
            if (!consume(p, '[') || !decimal(p, &item.value) || !consume(p, ']') ||
                !append_op(ops, op_count, item)) return 0;
        } else if (ch == '(') {
            Op item = {0};
            item.kind = OP_FUNCTION;
            if (!parse_params(p, &item.argc, item.param_type, item.param_ptrs) ||
                !append_op(ops, op_count, item)) return 0;
        } else break;
    }
    while (stars-- > 0) {
        Op item = {0};
        item.kind = OP_POINTER;
        if (!append_op(ops, op_count, item)) return 0;
    }
    return 1;
}
static int valid_type_order(int base, const Op ops[MAX_OPS], int count) {
    int current = 0; /* 0 base, 1 pointer, 2 array, 3 function */
    int current_is_void = base == TYPE_VOID;
    for (int i = count - 1; i >= 0; --i) {
        if (ops[i].kind == OP_ARRAY) {
            if (current == 3 || (current == 0 && current_is_void)) return 0;
            current = 2; current_is_void = 0;
        } else if (ops[i].kind == OP_FUNCTION) {
            if (current == 2 || current == 3) return 0;
            current = 3; current_is_void = 0;
        } else if (ops[i].kind == OP_POINTER) {
            current = 1; current_is_void = 0;
        } else return 0;
    }
    return 1;
}

int64_t prolangs_c_cdecl(const int64_t *input, size_t input_length,
                         uint8_t *output, size_t output_capacity) {
    if (!input || input_length < 1 || input_length > MAX_INPUT) return -1;
    for (size_t i = 0; i < input_length; ++i)
        if (input[i] <= 0 || input[i] > 127) return -1;
    Parser parser = { input, input_length, 0 };
    int base = base_type(&parser);
    char name[MAX_NAME + 1] = {0};
    Op ops[MAX_OPS] = {0};
    int op_count = 0;
    if (!base || !parse_declarator(&parser, name, ops, &op_count, 0) || !valid_type_order(base, ops, op_count) || (base == TYPE_VOID && op_count == 0)) return -1;
    if (peek(&parser) != -1) return -1;
    if (strcmp(name, "char") == 0 || strcmp(name, "int") == 0 || strcmp(name, "float") == 0 ||
        strcmp(name, "double") == 0 || strcmp(name, "void") == 0) return -1;

    uint8_t encoded[MAX_OUTPUT];
    size_t used = 0, name_length = strlen(name);
    encoded[used++] = (uint8_t)base;
    encoded[used++] = (uint8_t)name_length;
    for (size_t i = 0; i < name_length; ++i) encoded[used++] = (uint8_t)name[i];
    encoded[used++] = (uint8_t)op_count;
    for (int i = 0; i < op_count; ++i) {
        encoded[used++] = (uint8_t)ops[i].kind;
        if (ops[i].kind == OP_ARRAY) encoded[used++] = (uint8_t)ops[i].value;
        if (ops[i].kind == OP_FUNCTION) {
            encoded[used++] = (uint8_t)ops[i].argc;
            for (int a = 0; a < ops[i].argc; ++a) {
                encoded[used++] = (uint8_t)ops[i].param_type[a];
                encoded[used++] = (uint8_t)ops[i].param_ptrs[a];
            }
        }
    }
    if (!output || output_capacity < used) return -2;
    memcpy(output, encoded, used);
    return (int64_t)used;
}
