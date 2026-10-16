#include <stdint.h>
#include <stddef.h>
#define N 1023
int64_t diff_views_of_binary_tree(const int64_t *a, size_t n, int64_t root, int64_t view, int64_t *out, size_t cap) {
 if (n>N || view<0 || view>3) return -1;
 if (!n) return root==-1 ? 0 : -1;
 if (!a || root<0 || (uint64_t)root>=n) return -1;
 if (!out || cap<n) return -2;
 size_t parent[N]={0};
 for(size_t i=0;i<n;i++) { int64_t l=a[3*i+1],r=a[3*i+2],v=a[3*i]; if(v<INT32_MIN||v>INT32_MAX||l< -1||r< -1||(l>=0&&(uint64_t)l>=n)||(r>=0&&(uint64_t)r>=n))return -1; if(l>=0&&++parent[l]>1)return -1;if(r>=0&&++parent[r]>1)return -1; }
 if(parent[root])return -1;for(size_t i=0;i<n;i++)if(i!=(size_t)root&&parent[i]!=1)return -1;
 size_t q[N],head=0,tail=0,depth[N]; int col[N],seen[N]={0}; int64_t first_depth[N],last_depth[N],first_col[2*N+1],last_col[2*N+1];
 for(size_t i=0;i<N;i++)first_depth[i]=last_depth[i]=INT64_MIN;for(size_t i=0;i<2*N+1;i++)first_col[i]=last_col[i]=INT64_MIN;
 q[tail++]=(size_t)root;depth[root]=0;col[root]=0;seen[root]=1;size_t reached=0,maxdepth=0;int mincol=0,maxcol=0;
 while(head<tail){size_t u=q[head++],d=depth[u];int c=col[u];int64_t v=a[3*u]; reached++; if(d>maxdepth)maxdepth=d;if(c<mincol)mincol=c;if(c>maxcol)maxcol=c;
 if(first_depth[d]==INT64_MIN)first_depth[d]=v;last_depth[d]=v;size_t s=(size_t)(c+N);if(first_col[s]==INT64_MIN)first_col[s]=v;last_col[s]=v;
 int64_t kids[2]={a[3*u+1],a[3*u+2]};for(int k=0;k<2;k++)if(kids[k]>=0){size_t x=(size_t)kids[k];if(seen[x]||tail>=n)return -1;seen[x]=1;q[tail]=x;depth[x]=d+1;col[x]=c+(k?1:-1);tail++;}}
 if(reached!=n)return -1;size_t w=0;
 if(view<2){for(size_t d=0;d<=maxdepth;d++){int64_t v=view==0?last_depth[d]:first_depth[d];if(v!=INT64_MIN)out[w++]=v;}}
 else for(int c=mincol;c<=maxcol;c++){int64_t v=view==2?first_col[c+N]:last_col[c+N];if(v!=INT64_MIN)out[w++]=v;}
 return (int64_t)w;
}
