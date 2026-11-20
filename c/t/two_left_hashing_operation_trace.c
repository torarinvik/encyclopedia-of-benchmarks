#include <stddef.h>
#include <stdint.h>

#define OPS 40
#define KEYS 32
#define HALF 8
#define WORDS 161

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t j = 0; j < 8; ++j) out[at + j] = (uint8_t)(bits >> (8 * j));
}

int64_t two_left_hashing_operation_trace(const int64_t *in, size_t n,
                                        uint8_t *out, size_t cap) {
    if (!in || n < 5 || n > WORDS + 1) return -1;
    if (in[0] < 1 || in[0] > OPS || n != 1 + 4 * (size_t)in[0]) return -1;
    size_t q = (size_t)in[0];
    for (size_t i = 0; i < q; ++i) {
        int64_t op = in[1 + 4*i], key = in[2 + 4*i];
        int64_t left = in[3 + 4*i], right = in[4 + 4*i];
        if (op < 0 || op > 2 || key < 0 || key > 63 || left < 0 || left >= HALF || right < 0 || right >= HALF) return -1;
        for (size_t j = 0; j < i; ++j)
            if (in[2 + 4*j] == key && (in[3 + 4*j] != left || in[4 + 4*j] != right)) return -1;
    }
    size_t bytes = 16 * q;
    if (!out || cap < bytes) return -2;
    int head[16], next[KEYS], keys[KEYS], lengths[16];
    int64_t status[OPS], place[OPS];
    for (size_t b=0;b<16;++b) { head[b]=-1; lengths[b]=0; }
    for (size_t i=0;i<KEYS;++i) { next[i]=-1; keys[i]=-1; }
    size_t live=0;
    for (size_t i=0;i<q;++i) {
        int op=(int)in[1+4*i], key=(int)in[2+4*i];
        int lb=(int)in[3+4*i], rb=HALF+(int)in[4+4*i];
        int found=-1, found_bucket=-1;
        for (int b=0;b<2;++b) { int bucket=b==0?lb:rb; for(int x=head[bucket];x>=0;x=next[x]) if(keys[x]==key){found=x;found_bucket=bucket;break;} if(found>=0) break; }
        if (op==0) {
            if(found>=0){status[i]=0;place[i]=-1;continue;}
            if(live==KEYS) return -3;
            int use_left=lengths[lb]<=lengths[rb], bucket=use_left?lb:rb, node=0;
            while(keys[node]>=0) ++node;
            keys[node]=key; next[node]=head[bucket]; head[bucket]=node; ++lengths[bucket]; ++live;
            status[i]=1; place[i]=use_left?0:1;
        } else if(op==1) { status[i]=found>=0?1:0; place[i]=-1; }
        else {
            if(found<0){status[i]=0;place[i]=-1;continue;}
            int prev=-1,x=head[found_bucket]; while(x!=found){prev=x;x=next[x];}
            if(prev<0) head[found_bucket]=next[x]; else next[prev]=next[x];
            keys[x]=-1; next[x]=-1; --lengths[found_bucket]; --live; status[i]=1; place[i]=-1;
        }
    }
    for(size_t i=0;i<q;++i){put_i64(out,16*i,status[i]);put_i64(out,16*i+8,place[i]);}
    return (int64_t)bytes;
}
