#include <stddef.h>
#include <stdint.h>
#define MAX_TEXT 24u
#define MAX_PATTERN 12u
#define MAX_INPUT 39u
#define MAX_NODES 51u
typedef struct {size_t start,length,suffix,child_count;size_t children[MAX_NODES];} Node;
static int64_t code_at(const int64_t*in,size_t n,size_t p){return p==n?-1:in[1u+p];}
static void put64(uint8_t*out,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;j++){out[p+j]=(uint8_t)(b&255U);b>>=8;}}
static int suffix_less(const int64_t*in,size_t n,size_t a,size_t b){size_t p=0;while(a+p<=n&&b+p<=n){int64_t x=code_at(in,n,a+p),y=code_at(in,n,b+p);if(x!=y)return x<y;p++;}return a<b;}
int64_t suffix_tree_pattern_occurrences(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<3||len>MAX_INPUT)return -1;int64_t nr=in[0];if(nr<0||nr>(int64_t)MAX_TEXT)return -1;size_t n=(size_t)nr;if(len<2+n)return -1;int64_t mr=in[1+n];if(mr<1||mr>(int64_t)MAX_PATTERN||len!=2+n+(size_t)mr)return -1;size_t m=(size_t)mr;
 for(size_t i=0;i<n;i++)if(in[1+i]<0||in[1+i]>127)return -1;for(size_t i=0;i<m;i++)if(in[2+n+i]<0||in[2+n+i]>127)return -1;
 Node nodes[MAX_NODES]={0};size_t node_count=1;
 for(size_t start=0;start<=n;start++){size_t suffix_len=n+1-start,offset=0,node=0;while(offset<suffix_len){int64_t first=code_at(in,n,start+offset);size_t slot=0;while(slot<nodes[node].child_count&&code_at(in,n,nodes[nodes[node].children[slot]].start)!=first)slot++;
  if(slot==nodes[node].child_count){if(node_count>=MAX_NODES)return -1;size_t leaf=node_count++;nodes[leaf].start=start+offset;nodes[leaf].length=suffix_len-offset;nodes[leaf].suffix=start;nodes[node].children[nodes[node].child_count++]=leaf;break;}
  size_t child=nodes[node].children[slot],common=0;while(common<nodes[child].length&&offset+common<suffix_len&&code_at(in,n,start+offset+common)==code_at(in,n,nodes[child].start+common))common++;
  if(common==nodes[child].length){offset+=common;node=child;continue;}
  if(node_count>=MAX_NODES)return -1;size_t split=node_count++;nodes[split].start=nodes[child].start;nodes[split].length=common;nodes[split].children[0]=child;nodes[split].child_count=1;nodes[child].start+=common;nodes[child].length-=common;nodes[node].children[slot]=split;offset+=common;node=split;
 }}
 size_t node=0,offset=0;int matched=0;while(offset<m){size_t slot=0;int64_t wanted=in[2+n+offset];while(slot<nodes[node].child_count&&code_at(in,n,nodes[nodes[node].children[slot]].start)!=wanted)slot++;if(slot==nodes[node].child_count)break;size_t child=nodes[node].children[slot],common=0;while(common<nodes[child].length&&offset+common<m&&code_at(in,n,nodes[child].start+common)==in[2+n+offset+common])common++;if(offset+common==m){node=child;matched=1;break;}if(common!=nodes[child].length)break;offset+=common;node=child;}
 size_t starts[MAX_TEXT],count=0;if(matched){size_t stack[MAX_NODES],top=0;stack[top++]=node;while(top){size_t x=stack[--top];if(nodes[x].child_count==0&&nodes[x].length>0)starts[count++]=nodes[x].suffix;for(size_t j=0;j<nodes[x].child_count;j++)stack[top++]=nodes[x].children[j];}}
 for(size_t i=1;i<count;i++){size_t x=starts[i],j=i;while(j>0&&suffix_less(in,n,x,starts[j-1])){starts[j]=starts[j-1];j--;}starts[j]=x;}
 size_t bytes=8*(1+count);if(!out||cap<bytes)return -2;put64(out,0,(int64_t)count);for(size_t i=0;i<count;i++)put64(out,8+8*i,(int64_t)starts[i]);return (int64_t)bytes;
}
