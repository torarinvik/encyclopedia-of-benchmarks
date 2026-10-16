#include <stddef.h>
#include <stdint.h>

enum { LIST_BEGIN = 2001, LIST_END = 2002, MAX_TOKENS = 128, MAX_DEPTH = 16 };
typedef struct { const int64_t *tokens; size_t count, cursor; int valid; } Parser;

static int64_t parse_list(Parser *p, int depth, int nested) {
    int64_t sum = 0;
    if (depth > MAX_DEPTH) { p->valid = 0; return 0; }
    while (p->cursor < p->count) {
        int64_t token = p->tokens[p->cursor++];
        if (token == LIST_END) {
            if (!nested) p->valid = 0;
            return sum * depth;
        }
        if (token == LIST_BEGIN) sum += parse_list(p, depth + 1, 1);
        else if (token >= -1000 && token <= 1000) sum += token;
        else { p->valid = 0; return 0; }
        if (!p->valid) return 0;
    }
    if (nested) p->valid = 0;
    return sum * depth;
}

int64_t product_sum(const int64_t *v, size_t n) {
    if (!v || n < 1 || n > MAX_TOKENS + 1 || v[0] < 0 || v[0] > MAX_TOKENS || n != (size_t)v[0] + 1) return -1;
    Parser p = {v + 1, (size_t)v[0], 0, 1};
    int64_t result = parse_list(&p, 1, 0);
    return p.valid && p.cursor == p.count ? result : -1;
}
