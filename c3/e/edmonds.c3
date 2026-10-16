module edmonds;
const int NMAX=5; const int EMAX=12; const long INF=1000000000;
fn long edmonds(long* a, usz length) @export("edmonds") {
 if(a==null||length<3||length>39)return -1;
 long nn=a[0];long rr=a[1];long mm=a[2]; if(nn<1||nn>NMAX||rr<0||rr>=nn||mm<0||mm>EMAX||length!=3+3*(usz)mm)return -1;
 int n=(int)nn;int root=(int)rr;int m=(int)mm; int[EMAX] eu; int[EMAX] ev; long[EMAX] ew;
 for(int i=0;i<m;i++){long u=a[3+3*i];long v=a[4+3*i];long w=a[5+3*i];if(u<0||u>=n||v<0||v>=n||w<0||w>100)return -1;eu[i]=(int)u;ev[i]=(int)v;ew[i]=w;}
 long answer=0;
 while(true){long[NMAX] inn;int[NMAX] pre;for(int i=0;i<n;i++){inn[i]=INF;pre[i]=-1;}
  for(int i=0;i<m;i++)if(eu[i]!=ev[i]&&ev[i]!=root&&ew[i]<inn[ev[i]]){inn[ev[i]]=ew[i];pre[ev[i]]=eu[i];}
  inn[root]=0;for(int i=0;i<n;i++)if(inn[i]==INF)return -1;
  int[NMAX] id;int[NMAX] vis;for(int i=0;i<n;i++){id[i]=-1;vis[i]=-1;}int cycles=0;
  for(int i=0;i<n;i++){answer+=inn[i];int v=i;while(vis[v]!=i&&id[v]==-1&&v!=root){vis[v]=i;v=pre[v];}if(v!=root&&id[v]==-1){for(int u=pre[v];u!=v;u=pre[u])id[u]=cycles;id[v]=cycles++;}}
  if(cycles==0)return answer;
  for(int i=0;i<n;i++)if(id[i]==-1)id[i]=cycles++;
  for(int i=0;i<m;i++){int u=id[eu[i]];int v=id[ev[i]];if(u!=v)ew[i]-=inn[ev[i]];eu[i]=u;ev[i]=v;}
  root=id[root];n=cycles;
 }
}
