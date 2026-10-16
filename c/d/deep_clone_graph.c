#include <stddef.h>
#include <stdint.h>
#define MAX_N 16
static uint64_t mix(uint64_t h, uint64_t x) { for (int b=0;b<8;b++) { h^=(uint8_t)x; h*=UINT64_C(1099511628211); x>>=8; } return h; }
int64_t deep_clone_graph(const int64_t *a, size_t len) {
 if (!a || len<4 || len>2+2*MAX_N) return -1;
 int64_t n=a[0], root=a[1]; if(n<1||n>MAX_N||root<0||root>=n||len!=2+2*(size_t)n)return -1;
 uint64_t limit=(UINT64_C(1)<<n)-1, masks[MAX_N]={0}, clone_masks[MAX_N]={0}; int64_t labels[MAX_N], clone_labels[MAX_N]; int seen[MAX_N]={0}, stack[MAX_N*MAX_N], top=0, count=0;
 for(int i=0;i<n;i++){ if(a[2+i]<INT32_MIN||a[2+i]>INT32_MAX||a[2+n+i]<0||(uint64_t)a[2+n+i]>limit)return -1; labels[i]=a[2+i]; masks[i]=(uint64_t)a[2+n+i]; }
 for(int i=0;i<n;i++)for(int j=0;j<n;j++)if(((masks[i]>>j)&1)!=((masks[j]>>i)&1))return -1;
 stack[top++]=(int)root;
 while(top){ int u=stack[--top]; if(seen[u])continue; seen[u]=1; count++; clone_labels[u]=labels[u]; clone_masks[u]=0; for(int v=0;v<n;v++)if((masks[u]>>v)&1){ clone_masks[u]|=UINT64_C(1)<<v; if(!seen[v])stack[top++]=v; }}
 uint64_t h=UINT64_C(14695981039346656037); h=mix(h,(uint64_t)count);h=mix(h,(uint64_t)root);
 for(int i=0;i<n;i++)if(seen[i]){h=mix(h,(uint64_t)clone_labels[i]);h=mix(h,clone_masks[i]);}
 return (int64_t)h;
}
