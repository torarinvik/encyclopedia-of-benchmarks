#include <stddef.h>
#include <stdint.h>
int64_t kahn(const int64_t*v,size_t n){if(!v||n<2||n>258)return -2;int64_t nv=v[0],ne=v[1];if(nv<0||nv>32||ne<0||ne>128||n!=2+2*(size_t)ne)return -2;int adj[32][32]={0},ind[32]={0},q[32];for(size_t i=0;i<(size_t)ne;i++){int64_t a=v[2+2*i],b=v[3+2*i];if(a<0||a>=nv||b<0||b>=nv)return -2;if(!adj[a][b]){adj[a][b]=1;ind[b]++;}}int head=0,tail=0;for(int i=0;i<nv;i++)if(ind[i]==0)q[tail++]=i;while(head<tail){int x=q[head++];for(int y=0;y<nv;y++)if(adj[x][y]){ind[y]--;if(ind[y]==0)q[tail++]=y;}}return tail==nv?nv:-1;}
