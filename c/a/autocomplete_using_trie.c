#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 32
#define MAX_LEN 16
#define MAX_QUERIES 16
#define MAX_NODES (1 + MAX_WORDS * MAX_LEN)
#define MAX_OUTPUT_WORDS (1 + MAX_QUERIES * (1 + MAX_WORDS * (1 + MAX_LEN)))
typedef struct { int child[26]; int terminal; } Node;
static void init_node(Node *node){for(int i=0;i<26;++i)node->child[i]=-1;node->terminal=0;}
static void collect(const Node *nodes,int node,int *path,int depth,int64_t *out,size_t *used,size_t *count){
    if(nodes[node].terminal){out[(*used)++]=depth;for(int i=0;i<depth;++i)out[(*used)++]='a'+path[i];++*count;}
    for(int ch=0;ch<26;++ch)if(nodes[node].child[ch]>=0){path[depth]=ch;collect(nodes,nodes[node].child[ch],path,depth+1,out,used,count);}
}
static void put_i64(uint8_t *out,size_t index,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[index*8+b]=(uint8_t)(bits>>(8*b));}

int64_t autocomplete_using_trie(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<2||input[0]<0||input[0]>MAX_WORDS)return -1;
    size_t words=(size_t)input[0],pos=1;Node nodes[MAX_NODES];init_node(&nodes[0]);size_t node_count=1;
    for(size_t w=0;w<words;++w){if(pos>=length)return -1;int64_t len=input[pos++];if(len<1||len>MAX_LEN||pos+(size_t)len>length)return -1;int node=0;
        for(size_t j=0;j<(size_t)len;++j){int64_t ch=input[pos++];if(ch<'a'||ch>'z')return -1;int c=(int)(ch-'a');if(nodes[node].child[c]<0){if(node_count>=MAX_NODES)return -1;init_node(&nodes[node_count]);nodes[node].child[c]=(int)node_count++;}node=nodes[node].child[c];}
        nodes[node].terminal=1;
    }
    if(pos>=length)return -1;int64_t qv=input[pos++];if(qv<0||qv>MAX_QUERIES)return -1;size_t q=(size_t)qv;
    size_t query_pos[MAX_QUERIES],query_len[MAX_QUERIES];
    for(size_t i=0;i<q;++i){if(pos>=length)return -1;int64_t len=input[pos++];if(len<0||len>MAX_LEN||pos+(size_t)len>length)return -1;query_pos[i]=pos;query_len[i]=(size_t)len;for(size_t j=0;j<(size_t)len;++j)if(input[pos+j]<'a'||input[pos+j]>'z')return -1;pos+=(size_t)len;}
    if(pos!=length)return -1;
    int64_t result[MAX_OUTPUT_WORDS];size_t used=0;result[used++]=(int64_t)q;
    for(size_t i=0;i<q;++i){int node=0,path[MAX_LEN];int found=1;for(size_t j=0;j<query_len[i];++j){int c=(int)(input[query_pos[i]+j]-'a');path[j]=c;if(nodes[node].child[c]<0){found=0;break;}node=nodes[node].child[c];}
        size_t count_pos=used++;size_t count=0;if(found)collect(nodes,node,path,(int)query_len[i],result,&used,&count);result[count_pos]=(int64_t)count;
    }
    if(used>MAX_OUTPUT_WORDS)return -1;size_t required=used*8;if(output==NULL||capacity<required)return -2;
    for(size_t i=0;i<used;++i)put_i64(output,i,result[i]);return (int64_t)required;
}
