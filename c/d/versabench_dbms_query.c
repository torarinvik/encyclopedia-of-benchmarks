#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 7
#define MAX_ENTRIES 4
#define MAX_LEAF_RECORDS 16
#define MAX_INPUT_LENGTH (10 + 38 * MAX_NODES)
#define COORD_MIN (-8)
#define COORD_MAX 8

typedef struct { int64_t lo[4], hi[4], ref; } Entry;
typedef struct { int64_t level, count; Entry entries[MAX_ENTRIES]; } Node;

static int valid_box(const int64_t *lo, const int64_t *hi) {
    for (size_t d=0; d<4; ++d)
        if (lo[d] < COORD_MIN || lo[d] > COORD_MAX || hi[d] < COORD_MIN || hi[d] > COORD_MAX || lo[d] >= hi[d]) return 0;
    return 1;
}
static int intersects(const Entry *e, const int64_t *lo, const int64_t *hi) {
    for (size_t d=0; d<4; ++d) if (lo[d] > e->hi[d] || e->lo[d] > hi[d]) return 0;
    return 1;
}
static void write_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits=(uint64_t)value;
    for (size_t b=0;b<8;++b) out[at*8+b]=(uint8_t)(bits>>(8*b));
}

int64_t versabench_dbms_query(const int64_t *v, size_t length, uint8_t *output, size_t output_capacity) {
    if (v == NULL || length < 10 || length > MAX_INPUT_LENGTH + 1) return -1;
    int64_t nn=v[0], root_value=v[1];
    if (nn < 1 || nn > MAX_NODES || root_value < 0 || root_value >= nn) return -1;
    size_t node_count=(size_t)nn, root=(size_t)root_value;
    int64_t qlo[4], qhi[4];
    for (size_t d=0;d<4;++d) { qlo[d]=v[2+d]; qhi[d]=v[6+d]; }
    if (!valid_box(qlo,qhi)) return -1;
    Node nodes[MAX_NODES] = {0};
    size_t parents[MAX_NODES] = {0}, leaf_count=0, pos=10;
    unsigned char seen_ids[32] = {0};
    for (size_t ni=0; ni<node_count; ++ni) {
        if (pos+2 > length) return -1;
        int64_t level=v[pos++], ec=v[pos++];
        if (level < 0 || level > 2 || ec < 1 || ec > MAX_ENTRIES || pos + (size_t)ec*9 > length) return -1;
        nodes[ni].level=level; nodes[ni].count=ec;
        for (size_t ei=0; ei<(size_t)ec; ++ei) {
            Entry *e=&nodes[ni].entries[ei];
            for (size_t d=0;d<4;++d) e->lo[d]=v[pos++];
            for (size_t d=0;d<4;++d) e->hi[d]=v[pos++];
            e->ref=v[pos++];
            if (!valid_box(e->lo,e->hi)) return -1;
            if (level==0) {
                if (e->ref < 0 || e->ref >= 32 || seen_ids[e->ref] || ++leaf_count > MAX_LEAF_RECORDS) return -1;
                seen_ids[e->ref]=1;
            } else {
                if (e->ref < 0 || e->ref >= nn) return -1;
                if (++parents[e->ref] != 1) return -1;
            }
        }
    }
    if (pos != length || parents[root] != 0) return -1;
    for (size_t ni=0;ni<node_count;++ni) {
        if (ni != root && parents[ni] != 1) return -1;
        if (nodes[ni].level == 0) continue;
        for (size_t ei=0;ei<(size_t)nodes[ni].count;++ei) {
            Entry *branch=&nodes[ni].entries[ei];
            Node *child=&nodes[branch->ref];
            if (child->level != nodes[ni].level-1) return -1;
            for (size_t ce=0;ce<(size_t)child->count;++ce)
                for (size_t d=0;d<4;++d)
                    if (branch->lo[d] > child->entries[ce].lo[d] || branch->hi[d] < child->entries[ce].hi[d]) return -1;
        }
    }
    size_t stack[MAX_NODES], top=0, matches[MAX_LEAF_RECORDS], match_count=0;
    stack[top++]=root;
    while (top) {
        size_t ni=stack[--top]; Node *node=&nodes[ni];
        if (node->level==0) {
            for (size_t ei=0;ei<(size_t)node->count;++ei) if (intersects(&node->entries[ei],qlo,qhi)) matches[match_count++]=(size_t)node->entries[ei].ref;
        } else {
            for (size_t rev=(size_t)node->count;rev>0;--rev) {
                Entry *e=&node->entries[rev-1];
                if (intersects(e,qlo,qhi)) stack[top++]=(size_t)e->ref;
            }
        }
    }
    size_t bytes=match_count*8;
    if (output==NULL || output_capacity<bytes) return -2;
    for (size_t i=0;i<match_count;++i) write_i64_le(output,i,(int64_t)matches[i]);
    return (int64_t)bytes;
}
