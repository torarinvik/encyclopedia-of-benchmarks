#include <cstddef>
#include <cstdint>
namespace {
void put_i64(std::uint8_t*out,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++)out[i]=static_cast<std::uint8_t>(b>>(8*i));}
int power(int b,int e){int r=1;for(int i=0;i<e;i++)r*=b;return r;}
bool make_wedge(const std::int64_t*a,const std::int64_t*b,std::int64_t*out){std::int64_t c=-1;for(int i=0;i<2;i++)for(int j=0;j<2;j++)if(a[i]==b[j])c=a[i];if(c<0)return false;auto x=a[0]==c?a[1]:a[0];auto y=b[0]==c?b[1]:b[0];if(x==y)return false;if(x>y){auto q=x;x=y;y=q;}out[0]=x;out[1]=y;return true;}
}
extern "C" std::int64_t streaming_triangles(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(!input||length<10||length>340)return -1;auto n0=input[0],m0=input[1],se0=input[2],sw0=input[3];
    if(n0<2||n0>8||m0<1||m0>28||se0<2||se0>4||sw0<1||sw0>4)return -1;
    auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0),se=static_cast<std::size_t>(se0),sw=static_cast<std::size_t>(sw0),stride=2+2*sw;
    if(length!=4+2*m+m*stride)return -1;std::int64_t edges[28][2]{};bool seen[8][8]{};
    for(std::size_t i=0;i<m;i++){auto u=input[4+2*i],v=input[5+2*i];if(u<0||v<=u||v>=n0||seen[u][v])return -1;seen[u][v]=seen[v][u]=true;edges[i][0]=u;edges[i][1]=v;}
    int er[4]={-1,-1,-1,-1};std::int64_t wr[4][2]{};bool valid[4]{},closed[4]{};std::int64_t total=0,staged[84]{};std::size_t at=0,tape=4+2*m;
    for(std::size_t ti=0;ti<m;ti++){auto t=ti+1,rec=tape+ti*stride;for(std::size_t s=0;s<sw;s++)if(valid[s]&&wr[s][0]==edges[ti][0]&&wr[s][1]==edges[ti][1])closed[s]=true;
        auto draw=input[rec],slot0=input[rec+1];int lim=power(static_cast<int>(t),static_cast<int>(se)),threshold=lim-power(static_cast<int>(t)-1,static_cast<int>(se));if(draw<0||draw>=lim)return -1;bool update=draw<threshold;int fresh_count=0,removed_count=0;std::int64_t fresh[4][2]{};
        if(update){if(slot0<0||slot0>=static_cast<std::int64_t>(se))return -1;auto slot=static_cast<std::size_t>(slot0);int old_id=er[slot];if(old_id>=0)for(std::size_t j=0;j<se;j++)if(j!=slot&&er[j]>=0){std::int64_t old[2];if(make_wedge(edges[old_id],edges[er[j]],old))removed_count++;}er[slot]=static_cast<int>(ti);for(std::size_t j=0;j<se;j++)if(j!=slot&&er[j]>=0){std::int64_t out[2];if(make_wedge(edges[ti],edges[er[j]],out)){fresh[fresh_count][0]=out[0];fresh[fresh_count][1]=out[1];fresh_count++;}}}else if(slot0!=0)return -1;
        total+=fresh_count-removed_count;if(total<0)return -1;for(std::size_t s=0;s<sw;s++){auto wd=input[rec+2+2*s],pick=input[rec+3+2*s];if(fresh_count){if(wd<0||wd>=total)return -1;if(wd<fresh_count){if(pick<0||pick>=fresh_count)return -1;wr[s][0]=fresh[pick][0];wr[s][1]=fresh[pick][1];valid[s]=true;closed[s]=false;}else if(pick!=0)return -1;}else if(wd!=0||pick!=0)return -1;}
        int hits=0;for(std::size_t s=0;s<sw;s++)hits+=closed[s]?1:0;staged[at++]=total;staged[at++]=(3*hits*1000000)/static_cast<std::int64_t>(sw);staged[at++]=(static_cast<std::int64_t>(hits)*t*t*total*1000000)/static_cast<std::int64_t>(sw*se*(se-1));
    }
    auto bytes=24*m;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<at;i++)put_i64(output+8*i,staged[i]);return static_cast<std::int64_t>(bytes);
}
