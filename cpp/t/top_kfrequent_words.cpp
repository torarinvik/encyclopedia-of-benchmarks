#include <cstddef>
#include <cstdint>
#include <algorithm>

static bool greater_count(const int *heap, const int *counts, int a, int b) { return counts[heap[a]] > counts[heap[b]]; }
static void sift_down(int *heap, const int *counts, int size, int root) {
    int best = root, left = 2 * root + 1, right = left + 1;
    if (left < size && greater_count(heap, counts, left, best)) best = left;
    if (right < size && greater_count(heap, counts, right, best)) best = right;
    if (best != root) { int t = heap[root]; heap[root] = heap[best]; heap[best] = t; sift_down(heap, counts, size, best); }
}
extern "C" std::int64_t top_kfrequent_words(const std::int64_t *v, std::size_t n, std::uint8_t *out, std::size_t cap) {
    if (!v || n < 2 || n > 1090 || v[0] < 0 || v[0] > 64 || v[1] < 0 || v[1] > 64) return -1;
    int lens[64] = {}, counts[64] = {}, k = int(v[0]), wn = int(v[1]), distinct = 0, pos = 2;
    std::uint8_t words[64][16] = {};
    for (int w = 0; w < wn; ++w) {
        if (pos >= int(n) || v[pos] < 1 || v[pos] > 16 || v[pos] > int(n)-pos-1) return -1;
        int len = int(v[pos++]); for (int j=0;j<len;++j) if(v[pos+j]<'a'||v[pos+j]>'z') return -1;
        int id=0; for(;id<distinct;++id) if(lens[id]==len){int j=0;while(j<len&&words[id][j]==v[pos+j])++j;if(j==len)break;}
        if(id==distinct){lens[id]=len;for(int j=0;j<len;++j)words[id][j]=std::uint8_t(v[pos+j]);++distinct;} ++counts[id];pos+=len;
    }
    if(pos!=int(n))return -1;
    for(int id=0;id<distinct;++id){int rank=0;for(int other=0;other<distinct;++other){int common=std::min(lens[id],lens[other]),j=0;while(j<common&&words[other][j]==words[id][j])++j;if((j<common&&words[other][j]<words[id][j])||(j==common&&lens[other]<lens[id]))++rank;}counts[id]=counts[id]*65+distinct-rank;}
    int heap[64];for(int i=0;i<distinct;++i)heap[i]=i;
    for(int i=distinct/2-1;i>=0;--i)sift_down(heap,counts,distinct,i);
    int limit=k<distinct?k:distinct;std::uint8_t temp[1089]{};std::size_t at=0;
    for(int i=0;i<limit;++i){int id=heap[0];for(int j=0;j<lens[id];++j)temp[at++]=words[id][j];temp[at++]='\n';heap[0]=heap[--distinct];if(distinct)sift_down(heap,counts,distinct,0);}
    temp[at++]=0;if(!out||cap<at)return -2;for(std::size_t i=0;i<at;++i)out[i]=temp[i];return std::int64_t(at);
}
