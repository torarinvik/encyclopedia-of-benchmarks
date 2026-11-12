#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_INPUT=67, MAX_OUTPUT=504, MAX_N=32, MAX_H=63;
struct Context {
    const std::int64_t *concave, *arbitrary;
    std::size_t n, m, h;
    std::size_t y_min[MAX_H], y_max[MAX_H], x_min[MAX_N], x_max[MAX_N];
    std::int64_t result[MAX_H];
};
void store_i64_le(std::uint8_t *out,std::size_t at,std::int64_t value) {
    auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t k=0;k<8;++k){out[at+k]=static_cast<std::uint8_t>(bits&255u);bits>>=8;}
}
void block_rows(Context &c,std::size_t x1,std::size_t x2,std::size_t y1,std::size_t y2,
                std::size_t row1,std::size_t row2,std::size_t q1,std::size_t q2) {
    if(row1>row2)return;
    const auto mid=row1+(row2-row1)/2, x=x1+mid;
    auto best=std::numeric_limits<std::int64_t>::max(); auto best_q=q1;
    for(auto q=q1;q<=q2;++q){const auto y=y2-q;const auto v=c.arbitrary[y]+c.concave[x-y];if(v<best){best=v;best_q=q;}}
    c.result[x]=std::min(c.result[x],best);
    if(row1<mid)block_rows(c,x1,x2,y1,y2,row1,mid-1,q1,best_q);
    if(mid<row2)block_rows(c,x1,x2,y1,y2,mid+1,row2,best_q,q2);
}
void scan(Context &c,std::size_t x1,std::size_t x2,std::size_t y1,std::size_t y2){
    for(auto x=x1;x<=x2;++x){const auto lo=std::max(c.y_min[x],y1),hi=std::min(c.y_max[x],y2);if(lo>hi)continue;
        for(auto y=lo;y<=hi;++y)c.result[x]=std::min(c.result[x],c.arbitrary[y]+c.concave[x-y]);}
}
void partition(Context &c,std::size_t x1,std::size_t x2,std::size_t y1,std::size_t y2){
    if(x1>x2||y1>y2)return;
    if(c.y_max[x1]>=y2&&y1>=c.y_min[x2]){block_rows(c,x1,x2,y1,y2,0,x2-x1,0,y2-y1);return;}
    if((x2-x1)*(y2-y1)<1000){scan(c,x1,x2,y1,y2);return;}
    if(x2-x1>y2-y1){const auto mid=(x1+x2)/2;const auto ly=std::min(c.y_max[mid],y2);if(y1<=ly)partition(c,x1,mid,y1,ly);const auto ry=std::max(c.y_min[mid],y1);if(ry<=y2)partition(c,mid+1,x2,ry,y2);}
    else{const auto mid=(y1+y2)/2;const auto lx=std::min(c.x_max[mid],x2);if(x1<=lx)partition(c,x1,lx,y1,mid);const auto rx=std::max(c.x_min[mid],x1);if(rx<=x2)partition(c,rx,x2,mid+1,y2);}
}
}

extern "C" std::int64_t min_plus_convolution_concave_arbitrary(
    const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity){
    if(!input||length<4||length>MAX_INPUT)return -1;
    const auto n0=input[0],m0=input[1];if(n0<1||n0>MAX_N||m0<1||m0>MAX_N)return -1;
    const auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0);if(length!=2+n+m)return -1;
    const auto *a=input+2,*b=input+2+n;
    for(std::size_t i=0;i<n+m;++i)if(input[2+i]<0||input[2+i]>1000000000)return -1;
    for(std::size_t i=0;i+2<n;++i)if(a[i+1]-a[i]<a[i+2]-a[i+1])return -1;
    const auto h=n+m-1,bytes=8*h;if(bytes>MAX_OUTPUT)return -1;if(!output||capacity<bytes)return -2;
    Context c{};c.concave=a;c.arbitrary=b;c.n=m;c.m=n;c.h=h;
    for(std::size_t x=0;x<h;++x){c.y_min[x]=x>=n?x-n+1:0;c.y_max[x]=std::min(m-1,x);c.result[x]=std::numeric_limits<std::int64_t>::max();}
    for(std::size_t y=0;y<m;++y){c.x_min[y]=y;c.x_max[y]=n-1+y;}
    partition(c,0,h-1,0,m-1);
    for(std::size_t i=0;i<h;++i)store_i64_le(output,8*i,c.result[i]);
    return static_cast<std::int64_t>(bytes);
}
