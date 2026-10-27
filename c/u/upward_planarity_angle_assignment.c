/* Clean-room fixed-embedding angle-assignment flow profile, DOI 653. */
#include <stddef.h>
#include <stdint.h>

enum { MN=8, MM=18, MF=12, MI=124, MO=26 };
static void put64(uint8_t *p, int64_t x){ uint64_t u=(uint64_t)x; for(int i=0;i<8;i++){p[i]=(uint8_t)u;u>>=8;} }
static int aug(int t,int nslot,int slots[MN],int terms[MN],int inc[MN][MF],int owner[MN],int seen[MN],int assigned[MN]){
  for(int s=0;s<nslot;s++) if(inc[terms[t]][slots[s]]&&!seen[s]){seen[s]=1;if(owner[s]<0||aug(owner[s],nslot,slots,terms,inc,owner,seen,assigned)){owner[s]=t;assigned[t]=s;return 1;}}
  return 0;
}
static int suffix_match(int first,int r,int f,int cap[MF],int slots[MN],int terms[MN],int inc[MN][MF]){
  int ns=0,owner[MN],assigned[MN];for(int i=0;i<MN;i++)owner[i]=assigned[i]=-1;
  for(int j=0;j<f;j++)for(int k=0;k<cap[j];k++)slots[ns++]=j;
  for(int t=first;t<r;t++){int seen[MN]={0};if(!aug(t,ns,slots,terms,inc,owner,seen,assigned))return 0;}
  return 1;
}
int64_t upward_planarity_angle_assignment(const int64_t *a,size_t len,uint8_t *out,size_t capacity){
  if(!a||len<4||len>MI)return -1;
  int64_t nn=a[0],mm=a[1],ff=a[2],oo=a[3];
  if(nn<2||nn>MN||mm<1||mm>MM||ff<1||ff>MF||oo<0||oo>=ff||len!=(size_t)(4+6*mm+ff))return -1;
  int n=(int)nn,m=(int)mm,f=(int)ff,o=(int)oo;
  int eu[MM],ev[MM],adj[MN][MN]={0},outedge[MN][MN]={0},indeg[MN]={0};
  for(int i=0;i<m;i++){int64_t u=a[4+2*i],v=a[5+2*i];if(u<0||u>=n||v<0||v>=n||u==v)return -1;if(i&&(eu[i-1]>u||(eu[i-1]==u&&ev[i-1]>=v)))return -1;for(int j=0;j<i;j++)if((eu[j]==u&&ev[j]==v)||(eu[j]==v&&ev[j]==u))return -1;eu[i]=(int)u;ev[i]=(int)v;adj[u][v]=adj[v][u]=1;outedge[u][v]=1;indeg[v]++;}
  int walklen[MF],wu[2*MM],wv[2*MM],cursor=4+2*m,dart[MN][MN]={0},facecorner[MF][MN],incident[MN][MF]={0},succ[MN][MN],swt[MF][2]={0};
  for(int i=0;i<MF;i++)for(int v=0;v<MN;v++)facecorner[i][v]=-1;
  for(int v=0;v<MN;v++)for(int u=0;u<MN;u++)succ[v][u]=-1;
  int total=0;
  for(int j=0;j<f;j++){int64_t k=a[cursor++];if(k<1||k>2*m||total+k>2*m)return -1;walklen[j]=(int)k;for(int i=0;i<k;i++){int64_t u=a[cursor++],v=a[cursor++];if(u<0||u>=n||v<0||v>=n||!adj[u][v]||dart[u][v])return -1;dart[u][v]=1;wu[total]=(int)u;wv[total]=(int)v;total++;}}
  if(cursor!=(int)len||total!=2*m||n-m+f!=2)return -1;
  for(int i=0;i<m;i++)if(!dart[eu[i]][ev[i]]||!dart[ev[i]][eu[i]])return -1;
  cursor=0;
  for(int j=0;j<f;j++){int k=walklen[j],base=cursor;for(int i=0;i<k;i++){int u=wu[cursor],v=wv[cursor],w=wv[base+(i+1)%k];if(v!=wu[base+(i+1)%k]||succ[v][u]!=-1)return -1;succ[v][u]=w;if(facecorner[j][v]<0)facecorner[j][v]=i;incident[v][j]=1;int x=outedge[v][u],y=outedge[v][w];if(x&&y)swt[j][0]++;if(!x&&!y)swt[j][1]++;cursor++;}}
  int seen[MN]={0},stack[MN],sp=0;stack[sp++]=0;seen[0]=1;while(sp){int u=stack[--sp];for(int v=0;v<n;v++)if(adj[u][v]&&!seen[v])seen[v]=1,stack[sp++]=v;}for(int v=0;v<n;v++)if(!seen[v])return -1;
  int deg[MN],q[MN],head=0,tail=0;for(int v=0;v<n;v++){deg[v]=indeg[v];if(!deg[v])q[tail++]=v;}int removed=0;while(head<tail){int u=q[head++];removed++;for(int v=0;v<n;v++)if(outedge[u][v]&&--deg[v]==0)q[tail++]=v;}if(removed!=n)return -1;
  for(int v=0;v<n;v++){int d=0;for(int u=0;u<n;u++)d+=adj[v][u];if(d){int start=-1;for(int u=0;u<n;u++)if(adj[v][u]){if(succ[v][u]<0)return -1;start=u;}int cur=start,count=0,trans=0,prev=-1;do{if(cur<0||++count>d)return -1;int next=succ[v][cur];if((!!outedge[v][cur])!=(!!outedge[v][next]))trans++;prev=cur;cur=next;}while(cur!=start);(void)prev;if(count!=d||(trans!=0&&trans!=2))return -1;}}
  for(int j=0;j<f;j++)if(swt[j][0]!=swt[j][1])return -1;
  int cap[MF],terms[MN],r=0,sum=0,feasible=1;for(int j=0;j<f;j++){cap[j]=swt[j][0]+(j==o?1:-1);if(cap[j]<0)feasible=0;sum+=cap[j];}
  for(int v=0;v<n;v++){int d=0;for(int u=0;u<n;u++)d+=outedge[v][u];if(indeg[v]==0||d==0)terms[r++]=v;}if(sum!=r)feasible=0;
  if(!out||capacity<(size_t)(8*(2+3*r)))return -2;
  int slots[MN],chosen[MN];for(int i=0;i<MN;i++)chosen[i]=-1;
  int ok=feasible;for(int t=0;t<r&&ok;t++){int found=0;for(int face=0;face<f;face++)if(incident[terms[t]][face]&&cap[face]>0){cap[face]--;if(suffix_match(t+1,r,f,cap,slots,terms,incident)){chosen[t]=face;found=1;break;}cap[face]++;}if(!found)ok=0;}
  int64_t words[MO];words[0]=ok?1:0;words[1]=r;int z=2;for(int t=0;t<r;t++){if(ok){int face=chosen[t];words[z++]=terms[t];words[z++]=face;words[z++]=facecorner[face][terms[t]];}else{words[z++]=-1;words[z++]=-1;words[z++]=-1;}}
  for(int i=0;i<z;i++)put64(out+8*i,words[i]);return 8*z;
}
