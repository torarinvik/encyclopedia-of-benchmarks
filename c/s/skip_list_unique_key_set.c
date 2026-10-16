#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 128
#define MAX_LEVELS 8
#define MAX_KEY 2147483646LL
#define MIN_KEY (-2147483647LL)
typedef struct { int64_t key; int level; int next[MAX_LEVELS]; } Node;

static int random_level(uint32_t *state) {
    int level=1;
    do { *state ^= *state << 13; *state ^= *state >> 17; *state ^= *state << 5; if ((*state & 1U)!=0) break; ++level; } while(level<MAX_LEVELS);
    return level;
}
static int find_update(Node *nodes,int active,int64_t key,int update[MAX_LEVELS]) {
    int current=0;
    for(int level=active-1;level>=0;--level){while(nodes[current].next[level]!=0&&nodes[nodes[current].next[level]].key<key)current=nodes[current].next[level];update[level]=current;}
    return nodes[current].next[0];
}
static int contains(Node *nodes,int active,int64_t key) { int update[MAX_LEVELS]={0};int found=find_update(nodes,active,key,update);return found!=0&&nodes[found].key==key; }
static void insert(Node *nodes,int *next,int *active,uint32_t *rng,int64_t key) {
    int update[MAX_LEVELS]={0};(void)find_update(nodes,*active,key,update);int height=random_level(rng);
    if(height>*active){for(int level=*active;level<height;++level)update[level]=0;*active=height;}
    int id=(*next)++;nodes[id].key=key;nodes[id].level=height;
    for(int level=0;level<height;++level){nodes[id].next[level]=nodes[update[level]].next[level];nodes[update[level]].next[level]=id;}
}
static int erase(Node *nodes,int active,int64_t key) {
    int update[MAX_LEVELS]={0};int found=find_update(nodes,active,key,update);if(found==0||nodes[found].key!=key)return 0;
    for(int level=0;level<active;++level)if(nodes[update[level]].next[level]==found)nodes[update[level]].next[level]=nodes[found].next[level];return 1;
}
static void put_i64(uint8_t *output,size_t offset,int64_t value){uint64_t bits=(uint64_t)value;for(size_t byte=0;byte<8;++byte)output[offset+byte]=(uint8_t)(bits>>(8*byte));}

int64_t skip_list_unique_key_set(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<1||input[0]<0||input[0]>MAX_OPS||length!=1+2*(size_t)input[0])return -1;
    const size_t ops=(size_t)input[0];for(size_t i=0;i<ops;++i){const int64_t op=input[1+2*i],key=input[2+2*i];if(op<0||op>2||key<MIN_KEY||key>MAX_KEY)return -1;}
    Node nodes[MAX_OPS+1]={0};int next=1,active=1;uint32_t rng=0x9e3779b9U;
    for(size_t i=0;i<ops;++i){const int64_t op=input[1+2*i],key=input[2+2*i];
        if(op==0){if(contains(nodes,active,key))return -1;insert(nodes,&next,&active,&rng,key);}
        else if(op==1){(void)contains(nodes,active,key);}
        else if(!erase(nodes,active,key))return -1;
    }
    size_t count=0;for(int id=nodes[0].next[0];id!=0;id=nodes[id].next[0])++count;
    const size_t required=count*8;if(output==NULL||capacity<required)return -2;
    size_t index=0;for(int id=nodes[0].next[0];id!=0;id=nodes[id].next[0])put_i64(output,8*index++,nodes[id].key);
    return (int64_t)required;
}
