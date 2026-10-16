#include <stddef.h>
#include <stdint.h>

#define MAX_KEYS 128
#define NONE (-1)

typedef struct { int64_t key; int parent, child, left, right, degree; } Node;

static void store_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

static void remove_ring(Node *nodes, int x) { nodes[nodes[x].left].right=nodes[x].right; nodes[nodes[x].right].left=nodes[x].left; }
static void add_root(Node *nodes, int *minimum, int x) {
    nodes[x].parent=NONE;
    if (*minimum==NONE) { nodes[x].left=nodes[x].right=x; *minimum=x; }
    else { int m=*minimum, r=nodes[m].right; nodes[x].left=m; nodes[x].right=r; nodes[m].right=x; nodes[r].left=x; if(nodes[x].key<nodes[m].key)*minimum=x; }
}
static void link_child(Node *a, int parent, int child) {
    remove_ring(a,child); a[child].parent=parent;
    if(a[parent].child==NONE){a[child].left=a[child].right=child;a[parent].child=child;}
    else {int c=a[parent].child,r=a[c].right;a[child].left=c;a[child].right=r;a[c].right=child;a[r].left=child;}
    ++a[parent].degree;
}
static void consolidate(Node *a, int *minimum) {
    int roots[MAX_KEYS], count=0, x=*minimum;
    if(x==NONE)return;
    do { roots[count++]=x; x=a[x].right; } while(x!=*minimum);
    int by_degree[MAX_KEYS+1]; for(int i=0;i<=MAX_KEYS;++i)by_degree[i]=NONE;
    for(int i=0;i<count;++i){x=roots[i];if(a[x].parent!=NONE)continue;int d=a[x].degree;
        while(by_degree[d]!=NONE){int y=by_degree[d];if(a[y].key<a[x].key){int t=x;x=y;y=t;}by_degree[d]=NONE;link_child(a,x,y);d=a[x].degree;}
        by_degree[d]=x;
    }
    *minimum=NONE;
    for(int d=0;d<=MAX_KEYS;++d)if(by_degree[d]!=NONE)add_root(a,minimum,by_degree[d]);
}

int64_t fibonacci_heap(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if((input==NULL&&length>0)||length>MAX_KEYS)return -1;
    for(size_t i=0;i<length;++i)if(input[i]<INT32_MIN||input[i]>INT32_MAX)return -1;
    size_t bytes=length*8;
    if(capacity<bytes||(length>0&&output==NULL))return -2;
    Node nodes[MAX_KEYS]; int minimum=NONE;
    for(size_t i=0;i<length;++i){nodes[i].key=input[i];nodes[i].parent=nodes[i].child=NONE;nodes[i].degree=0;nodes[i].left=nodes[i].right=(int)i;add_root(nodes,&minimum,(int)i);}
    for(size_t out=0;out<length;++out){int z=minimum;store_i64_le(output,out*8,nodes[z].key);
        if(nodes[z].child!=NONE){int children[MAX_KEYS],c=nodes[z].child,k=0;do{children[k++]=c;c=nodes[c].right;}while(c!=nodes[z].child);for(int j=0;j<k;++j)add_root(nodes,&minimum,children[j]);}
        remove_ring(nodes,z);if(nodes[z].right==z)minimum=NONE;else{minimum=nodes[z].right;consolidate(nodes,&minimum);}
    }
    return (int64_t)bytes;
}
