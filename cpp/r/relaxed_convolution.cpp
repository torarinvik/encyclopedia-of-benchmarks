// New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
#include <cstddef>
#include <cstdint>
static constexpr std::int64_t MOD=998244353;
extern "C" std::int64_t relaxed_convolution(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<3||length>33)return -1;auto n0=input[0];if(n0<1||n0>16||length!=1+2*static_cast<std::size_t>(n0))return -1;int n=static_cast<int>(n0);std::int64_t a[16]{},b[16]{},c[16]{};
    for(int i=0;i<n;i++){a[i]=input[1+i];b[i]=input[1+n+i];if(a[i]<0||a[i]>=MOD||b[i]<0||b[i]>=MOD)return -1;}if(output==nullptr||capacity<static_cast<std::size_t>(4*n))return -2;
    for(int index=0;index<n;index++){c[index]=(c[index]+a[index]*b[0]+(index?b[index]*a[0]:0))%MOD;int q=index+1;
        for(int d=1;d<=q;d*=2){if(q%(2*d)!=d)continue;int end=q+d<n?q+d:n;
            if(q==d){for(int i=q;i<end;i++){int target=d+i-q;for(int r=0;r<d;r++){int y=target-r;if(y<d)c[i]=(c[i]+a[r]*b[y])%MOD;}}}
            else{for(int i=q;i<end;i++){int target=d+i-q;for(int r=0;r<d;r++){int y=target-r;if(y<2*d)c[i]=(c[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y])%MOD;}}}
        }
    }
    for(int i=0;i<n;i++){auto x=static_cast<std::uint32_t>(c[i]);for(int j=0;j<4;j++)output[4*i+j]=static_cast<std::uint8_t>(x>>(8*j));}return 4*n;
}
