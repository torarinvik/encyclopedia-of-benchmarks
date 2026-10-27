/* Clean-room fixed-embedding angle-assignment flow profile, DOI 653. */
#include <algorithm>
#include <cstddef>
#include <cstdint>
namespace {
constexpr int MN=8,MM=18,MF=12,MI=124,MO=26;
void put64(std::uint8_t*p,std::int64_t x){auto u=(std::uint64_t)x;for(int i=0;i<8;i++){p[i]=(std::uint8_t)u;u>>=8;}}
bool aug(int t,int ns,const int slots[MN],const int terms[MN],const int inc[MN][MF],int owner[MN],bool seen[MN],int assigned[MN]){for(int s=0;s<ns;s++)if(inc[terms[t]][slots[s]]&&!seen[s]){seen[s]=true;if(owner[s]<0||aug(owner[s],ns,slots,terms,inc,owner,seen,assigned)){owner[s]=t;assigned[t]=s;return true;}}return false;}
bool suffix_match(int first,int r,int f,int cap[MF],int slots[MN],const int terms[MN],const int inc[MN][MF]){int ns=0,owner[MN],assigned[MN];for(int i=0;i<MN;i++)owner[i]=assigned[i]=-1;for(int j=0;j<f;j++)for(int k=0;k<cap[j];k++)slots[ns++]=j;for(int t=first;t<r;t++){bool seen[MN]{};if(!aug(t,ns,slots,terms,inc,owner,seen,assigned))return false;}return true;}
}
extern "C" std::int64_t upward_planarity_angle_assignment(const std::int64_t*a,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{
 if(!a||len<4||len>MI)return -1;auto nn=a[0],mm=a[1],ff=a[2],oo=a[3];if(nn<2||nn>MN||mm<1||mm>MM||ff<1||ff>MF||oo<0||oo>=ff||len!=(std::size_t)(4+6*mm+ff))return -1;int n=nn,m=mm,f=ff,o=oo;
 int eu[MM],ev[MM],adj[MN][MN]{},oe[MN][MN]{},indeg[MN]{};
 for(int i=0;i<m;i++){auto u=a[4+2*i],v=a[5+2*i];if(u<0||u>=n||v<0||v>=n||u==v||(i&&(eu[i-1]>u||(eu[i-1]==u&&ev[i-1]>=v))))return -1;for(int j=0;j<i;j++)if((eu[j]==u&&ev[j]==v)||(eu[j]==v&&ev[j]==u))return -1;eu[i]=u;ev[i]=v;adj[u][v]=adj[v][u]=1;oe[u][v]=1;indeg[v]++;}
 int wl[MF],wu[2*MM],wv[2*MM],cur=4+2*m,dart[MN][MN]{},fc[MF][MN],inc[MN][MF]{},succ[MN][MN],sw[MF][2]{};for(auto&row:fc)for(int&x:row)x=-1;for(auto&row:succ)for(int&x:row)x=-1;int total=0;
 for(int j=0;j<f;j++){auto k=a[cur++];if(k<1||k>2*m||total+k>2*m)return -1;wl[j]=k;for(int i=0;i<k;i++){auto u=a[cur++],v=a[cur++];if(u<0||u>=n||v<0||v>=n||!adj[u][v]||dart[u][v])return -1;dart[u][v]=1;wu[total]=u;wv[total++]=v;}}
 if(cur!=(int)len||total!=2*m||n-m+f!=2)return -1;for(int i=0;i<m;i++)if(!dart[eu[i]][ev[i]]||!dart[ev[i]][eu[i]])return -1;cur=0;
 for(int j=0;j<f;j++){int k=wl[j],base=cur;for(int i=0;i<k;i++){int u=wu[cur],v=wv[cur],w=wv[base+(i+1)%k];if(v!=wu[base+(i+1)%k]||succ[v][u]>=0)return -1;succ[v][u]=w;if(fc[j][v]<0)fc[j][v]=i;inc[v][j]=1;bool x=oe[v][u],y=oe[v][w];if(x&&y)sw[j][0]++;if(!x&&!y)sw[j][1]++;cur++;}}
 bool seen[MN]{};int q[MN],h=0,t=0;q[t++]=0;seen[0]=true;while(h<t){int u=q[h++];for(int v=0;v<n;v++)if(adj[u][v]&&!seen[v])seen[v]=true,q[t++]=v;}for(int v=0;v<n;v++)if(!seen[v])return -1;
 int d[MN],q2[MN],hh=0,tt=0;for(int v=0;v<n;v++){d[v]=indeg[v];if(!d[v])q2[tt++]=v;}int rem=0;while(hh<tt){int u=q2[hh++];rem++;for(int v=0;v<n;v++)if(oe[u][v]&&--d[v]==0)q2[tt++]=v;}if(rem!=n)return -1;
 for(int v=0;v<n;v++){int dv=0;for(int u=0;u<n;u++)dv+=adj[v][u];if(dv){int start=-1;for(int u=0;u<n;u++)if(adj[v][u]){if(succ[v][u]<0)return -1;start=u;}int x=start,cnt=0,tr=0;do{if(x<0||++cnt>dv)return -1;int y=succ[v][x];tr+=(bool(oe[v][x])!=bool(oe[v][y]));x=y;}while(x!=start);if(cnt!=dv||(tr!=0&&tr!=2))return -1;}}
 int c[MF],terms[MN],r=0,sum=0;bool feasible=true;for(int j=0;j<f;j++){if(sw[j][0]!=sw[j][1])return -1;c[j]=sw[j][0]+(j==o?1:-1);if(c[j]<0)feasible=false;sum+=c[j];}for(int v=0;v<n;v++){int od=0;for(int u=0;u<n;u++)od+=oe[v][u];if(indeg[v]==0||od==0)terms[r++]=v;}if(sum!=r)feasible=false;
 if(!out||cap<(std::size_t)(8*(2+3*r)))return -2;int slots[MN],chosen[MN];for(int i=0;i<MN;i++)chosen[i]=-1;bool ok=feasible;for(int i=0;i<r&&ok;i++){bool found=false;for(int face=0;face<f;face++)if(inc[terms[i]][face]&&c[face]>0){c[face]--;if(suffix_match(i+1,r,f,c,slots,terms,inc)){chosen[i]=face;found=true;break;}c[face]++;}if(!found)ok=false;}
 std::int64_t w[MO];w[0]=ok?1:0;w[1]=r;int z=2;for(int i=0;i<r;i++){if(ok){int face=chosen[i];w[z++]=terms[i];w[z++]=face;w[z++]=fc[face][terms[i]];}else{w[z++]=-1;w[z++]=-1;w[z++]=-1;}}for(int i=0;i<z;i++)put64(out+8*i,w[i]);return 8*z;
}
