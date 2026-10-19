/* BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
 * Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 128
#define MAX_STREAM_BYTES 258
#define EXCLUDED 32000
typedef struct { uint8_t c; float freq; int parent, left, right; } HuffNode;

static void put_u32(uint8_t *out, uint32_t x) { for (size_t i=0;i<4;++i) out[i]=(uint8_t)(x>>(8*i)); }
int64_t nbench_huffman_compression(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input==NULL || length<2 || length>MAX_TEXT+1) return -1;
    int64_t raw_n=input[0];
    if (raw_n<1 || raw_n>MAX_TEXT || length!=(size_t)raw_n+1) return -1;
    size_t n=(size_t)raw_n, arraysize=n+1;
    uint8_t text[MAX_TEXT+1]; bool seen[256]={false}; size_t distinct=0;
    for(size_t i=0;i<n;++i){if(input[i+1]<32||input[i+1]>47)return -1;text[i]=(uint8_t)input[i+1];if(!seen[text[i]]){seen[text[i]]=true;++distinct;}}
    text[n]=0;if(!seen[0])++distinct;if(distinct<2)return -1;
    HuffNode tree[512];
    for(int i=0;i<256;++i){tree[i].freq=0.0f;tree[i].c=(uint8_t)i;tree[i].parent=tree[i].left=tree[i].right=-1;}
    for(size_t j=0;j<arraysize;++j)tree[text[j]].freq+=1.0f;
    for(int i=0;i<256;++i)if(tree[i].freq!=0.0f)tree[i].freq=(float)(tree[i].freq/(float)arraysize);
    for(int i=256;i<512;++i){tree[i].c=0;tree[i].freq=0.0f;tree[i].parent=EXCLUDED;tree[i].left=tree[i].right=0;}
    for(int i=0;i<512;++i){if(tree[i].freq==0.0f)tree[i].parent=EXCLUDED;else tree[i].parent=tree[i].left=tree[i].right=-1;}
    int root=255;
    for(;;){float low1=2.0f,low2=2.0f;int idx1=-1,idx2=-1;
        for(int i=0;i<=root;++i)if(tree[i].parent<0&&tree[i].freq<low1){low1=tree[i].freq;idx1=i;}
        if(idx1<0)break;
        for(int i=0;i<=root;++i)if(tree[i].parent<0&&i!=idx1&&tree[i].freq<low2){low2=tree[i].freq;idx2=i;}
        if(idx2<0)break;
        ++root;tree[idx1].parent=root;tree[idx2].parent=root;tree[root].freq=low1+low2;tree[root].left=idx1;tree[root].right=idx2;tree[root].parent=-2;
    }
    if(root<256||tree[root].left<0)return -1;
    uint8_t stream[MAX_STREAM_BYTES]={0};size_t bit_count=0;
    for(size_t j=0;j<arraysize;++j){int path[30],path_len=0,node=text[j];while(tree[node].parent!=-2){int p=tree[node].parent;if(p<0||p>=512||path_len>=30)return -1;path[path_len++]=(tree[p].left==node)?0:1;node=p;}while(path_len>0){int bit=path[--path_len];if(bit)stream[bit_count>>3]|=(uint8_t)(1u<<(bit_count&7));++bit_count;}}
    uint8_t decoded[MAX_TEXT+1];size_t bit=0,textpos=0;
    while(bit<bit_count){int node=root;while(tree[node].left!=-1){int b=(stream[bit>>3]>>(bit&7))&1;node=b?tree[node].right:tree[node].left;++bit;if(bit>bit_count)return -1;}if(textpos>=arraysize)return -1;decoded[textpos++]=tree[node].c;}
    if(textpos!=arraysize)return -1;for(size_t i=0;i<arraysize;++i)if(decoded[i]!=text[i])return -1;
    size_t stream_bytes=(bit_count+7)/8,total_bytes=4+stream_bytes;
    if(output==NULL||capacity<total_bytes)return -2;
    put_u32(output,(uint32_t)bit_count);for(size_t i=0;i<stream_bytes;++i)output[4+i]=stream[i];
    return (int64_t)total_bytes;
}
