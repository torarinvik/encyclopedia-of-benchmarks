#include <stddef.h>
#include <stdint.h>
#define MAX_NODES 256
#define MAX_QUERIES 1024
#define LOG_LEVELS 9
static void put_i64(uint8_t *out,size_t slot,int64_t value){uint64_t b=(uint64_t)value;for(size_t i=0;i<8;++i)out[slot*8+i]=(uint8_t)(b>>(8*i));}
int64_t binary_lifting_kth_ancestor(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<4||input[0]<1||input[0]>MAX_NODES)return -1;size_t n=(size_t)input[0];if(input[1]<0||input[1]>=(int64_t)n||input[2]!=(int64_t)(n-1)||input[3]<0||input[3]>MAX_QUERIES)return -1;size_t m=(size_t)input[2],q=(size_t)input[3],qo=4+2*m;if(length!=qo+2*q)return -1;size_t root=(size_t)input[1];
 uint8_t adj[MAX_NODES][MAX_NODES]={{0}};for(size_t e=0;e<m;++e){int64_t a=input[4+2*e],b=input[5+2*e];if(a<0||a>=(int64_t)n||b<0||b>=(int64_t)n||a==b)return -1;adj[a][b]=adj[b][a]=1;}
 for(size_t i=0;i<q;++i){int64_t v=input[qo+2*i],k=input[qo+2*i+1];if(v<0||v>=(int64_t)n||k<0)return -1;}
 size_t up[LOG_LEVELS][MAX_NODES]={{0}},stack[MAX_NODES],depth[MAX_NODES]={0};int64_t parent[MAX_NODES];for(size_t i=0;i<n;++i)parent[i]=-1;size_t top=0,reached=0;parent[root]=(int64_t)root;up[0][root]=root;stack[top++]=root;
 while(top){size_t u=stack[--top];++reached;for(size_t v=0;v<n;++v)if(adj[u][v]){if((int64_t)v==parent[u])continue;if(parent[v]!=-1)return -1;parent[v]=(int64_t)u;depth[v]=depth[u]+1;up[0][v]=u;stack[top++]=v;}}if(reached!=n)return -1;
 for(size_t level=1;level<LOG_LEVELS;++level)for(size_t v=0;v<n;++v)up[level][v]=up[level-1][up[level-1][v]];
 size_t bytes=(1+q)*8;if(!output||capacity<bytes)return -2;put_i64(output,0,(int64_t)q);
 for(size_t i=0;i<q;++i){size_t v=(size_t)input[qo+2*i];uint64_t k=(uint64_t)input[qo+2*i+1];if(k>=n)v=root;else for(size_t bit=0;bit<LOG_LEVELS;++bit)if(k&((uint64_t)1<<bit))v=up[bit][v];put_i64(output,1+i,(int64_t)v);}return (int64_t)bytes;
}
