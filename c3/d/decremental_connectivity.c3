module decremental_connectivity;
const int NMAX=32; const int QMAX=128;
fn int dc_find(int* p,int x){while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x;}
fn int dc_side(ulong* adj,int n,int start,int* out){bool[32] seen;int[32] stack;int top=0;int count=0;stack[top++]=start;while(top>0){int u=stack[--top];if(seen[u])continue;seen[u]=true;out[count++]=u;for(int v=0;v<n;v++)if(((adj[u]>>v)&1)!=0&&!seen[v])stack[top++]=v;}return count;}
fn long decremental_connectivity(long* a, usz len) @export("decremental_connectivity") {
 if(a==null||len<3||len>449)return -1;long n0=a[0];long m0=a[1];if(n0<1||n0>32||m0<0||m0>=n0)return -1;int n=(int)n0;int m=(int)m0;usz ep=2+2*(usz)m;if(len<=ep)return -1;long q0=a[ep];if(q0<0||q0>128||len!=ep+1+3*(usz)q0)return -1;int q=(int)q0;
 ulong[32] adj;int[32] parent;for(int i=0;i<n;i++)parent[i]=i;
 for(int i=0;i<m;i++){long u0=a[2+2*i];long v0=a[3+2*i];if(u0<0||u0>=n||v0<0||v0>=n||u0==v0)return -1;int u=(int)u0;int v=(int)v0;if(((adj[u]>>v)&1)!=0)return -1;int ru=dc_find(&parent[0],u);int rv=dc_find(&parent[0],v);if(ru==rv)return -1;parent[rv]=ru;adj[u]|=(ulong)1<<v;adj[v]|=(ulong)1<<u;}
 int[32] comp;for(int i=0;i<n;i++)comp[i]=-1;int next=0;int[32] stack;for(int s=0;s<n;s++)if(comp[s]<0){int top=0;stack[top++]=s;comp[s]=next;while(top>0){int u=stack[--top];for(int v=0;v<n;v++)if(((adj[u]>>v)&1)!=0&&comp[v]<0){comp[v]=next;stack[top++]=v;}}next++;}
 ulong h=14695981039346656037;for(int k=0;k<q;k++){usz p=ep+1+3*(usz)k;long op=a[p];long u0=a[p+1];long v0=a[p+2];if((op!=0&&op!=1)||u0<0||u0>=n||v0<0||v0>=n)return -1;int u=(int)u0;int v=(int)v0;if(op==1){h=(h^(ulong)(comp[u]==comp[v]))*1099511628211;continue;}if(((adj[u]>>v)&1)==0||comp[u]!=comp[v])return -1;adj[u]&=~((ulong)1<<v);adj[v]&=~((ulong)1<<u);int[32] left;int[32] right;int lc=dc_side(&adj[0],n,u,&left[0]);int rc=dc_side(&adj[0],n,v,&right[0]);int* small=&right[0];int sc=rc;if(lc<rc||(lc==rc&&u<v)){small=&left[0];sc=lc;}for(int j=0;j<sc;j++)comp[small[j]]=next;next++;}
 return (long)h;
}
