#include <stddef.h>
#include <stdint.h>
#define MAX_OPS 128
#define ROOTS 9
#define EMPTY (-1)
typedef struct { int64_t value; int child, sibling, degree; } Node;
typedef struct { Node nodes[MAX_OPS]; int roots[ROOTS], used, size; } Heap;
static int link_trees(Heap *h,int a,int b){int p,c;if(h->nodes[a].value<h->nodes[b].value){p=a;c=b;}else{p=b;c=a;}h->nodes[c].sibling=h->nodes[p].child;h->nodes[p].child=c;++h->nodes[p].degree;return p;}
static void add_tree(Heap *h,int root){int d=h->nodes[root].degree;while(h->roots[d]!=EMPTY){root=link_trees(h,root,h->roots[d]);h->roots[d++]=EMPTY;}h->roots[d]=root;}
static void init(Heap*h){h->used=h->size=0;for(int i=0;i<ROOTS;i++)h->roots[i]=EMPTY;}
static void insert(Heap*h,int64_t v){int r=h->used++;h->nodes[r]=(Node){v,EMPTY,EMPTY,0};++h->size;add_tree(h,r);}
static int min_root(const Heap*h){int b=EMPTY;for(int d=0;d<ROOTS;d++){int r=h->roots[d];if(r!=EMPTY&&(b==EMPTY||h->nodes[r].value<h->nodes[b].value))b=r;}return b;}
static int64_t extract_min(Heap*h){int b=min_root(h),d=h->nodes[b].degree;int64_t v=h->nodes[b].value;h->roots[d]=EMPTY;int c=h->nodes[b].child;while(c!=EMPTY){int next=h->nodes[c].sibling;h->nodes[c].sibling=EMPTY;add_tree(h,c);c=next;}--h->size;return v;}
static void put_i64(uint8_t*out,size_t i,int64_t v){uint64_t bits=(uint64_t)v;for(size_t b=0;b<8;b++)out[i*8+b]=(uint8_t)(bits>>(8*b));}
int64_t binomial_heap(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<1||in[0]<0||in[0]>MAX_OPS||len!=1+2*(size_t)in[0])return -1;size_t n=(size_t)in[0],q=0;int size=0;for(size_t i=0;i<n;i++){int64_t op=in[1+2*i],v=in[2+2*i];if(op==0){if(v<INT32_MIN||v>INT32_MAX)return -1;++size;}else if(op>=1&&op<=3){if(v!=0||((op==1||op==2)&&size==0))return -1;if(op==2)--size;++q;}else return -1;}size_t need=q*8;if(cap<need||(need&&!out))return -2;Heap h;init(&h);size_t w=0;for(size_t i=0;i<n;i++){int64_t op=in[1+2*i],v=in[2+2*i],r;if(op==0){insert(&h,v);continue;}if(op==1)r=h.nodes[min_root(&h)].value;else if(op==2)r=extract_min(&h);else r=h.size==0?1:0;put_i64(out,w++,r);}return (int64_t)w;}
