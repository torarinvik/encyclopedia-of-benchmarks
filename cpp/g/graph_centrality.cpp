#include <cstddef>
#include <cstdint>
#include <limits>
static void put64(std::uint8_t *o,std::size_t a,std::int64_t v){auto x=(std::uint64_t)v;for(int b=0;b<8;++b)o[a*8+b]=(std::uint8_t)(x>>(8*b));}
extern "C" std::int64_t graph_centrality(const std::int64_t *in,std::size_t len,std::uint8_t *out,std::size_t cap){
 if(!in||len<2)return -1;auto nn=in[0],ee=in[1];if(nn<1||nn>16||ee<0||ee>nn*(nn-1)||len!=2+3*(std::size_t)ee)return -1;int n=(int)nn,e=(int)ee;std::int64_t d[16][16];auto inf=std::numeric_limits<std::int64_t>::max();for(int i=0;i<n;++i)for(int j=0;j<n;++j)d[i][j]=i==j?0:inf;
 for(int x=0;x<e;++x){auto a=in[2+3*x],b=in[3+3*x],w=in[4+3*x];if(a<0||a>=n||b<0||b>=n||a==b||w<1||w>1000000||d[a][b]!=inf)return -1;d[a][b]=w;}
 for(int k=0;k<n;++k)for(int i=0;i<n;++i)if(d[i][k]!=inf)for(int j=0;j<n;++j)if(d[k][j]!=inf&&d[i][k]+d[k][j]<d[i][j])d[i][j]=d[i][k]+d[k][j];
 std::int64_t c=-1,m=-1,be=inf;double bh=-1;if(n==1)c=m=0;else for(int i=0;i<n;++i){int r=0;std::int64_t ec=0;double h=0;for(int j=0;j<n;++j)if(i!=j&&d[i][j]!=inf){++r;if(d[i][j]>ec)ec=d[i][j];h+=1.0/(double)d[i][j];}if(r&&ec<be){be=ec;c=i;}if(r&&h>bh){bh=h;m=i;}}
 if(!out||cap<16)return -2;put64(out,0,c);put64(out,1,m);return 16;
}
