#include <array>
#include <cstddef>
#include <cstdint>
static constexpr int64_t p=998244353;
static int64_t power(int64_t x,int e) {
    int64_t result=1;
    while (e>0) { if (e&1) result=result*x%p; x=x*x%p; e>>=1; }
    return result;
}
extern "C" int64_t inv_of_formal_power_series_2d(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if (!input || length<3 || length>66 || input[0]<1 || input[0]>8 || input[1]<1 || input[1]>8) return -1;
    int n=static_cast<int>(input[0]), m=static_cast<int>(input[1]);
    if (length!=2+static_cast<size_t>(n*m) || input[2]==0) return -1;
    for (int i=0;i<n*m;++i) if (input[2+i]<0 || input[2+i]>=p) return -1;
    if (!output || capacity<8*static_cast<size_t>(n*m)) return -2;
    std::array<int64_t,64> g{};
    int64_t inverse=power(input[2],static_cast<int>(p-2)); g[0]=inverse;
    for (int i=0;i<n;++i) for (int j=0;j<m;++j) {
        if (i==0 && j==0) continue;
        int64_t sum=0;
        for (int a=0;a<=i;++a) for (int b=0;b<=j;++b)
            if (a!=0 || b!=0) sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b])%p;
        g[i*m+j]=((p-sum)%p)*inverse%p;
    }
    for (int i=0;i<n*m;++i) {
        auto bits=static_cast<uint64_t>(g[i]);
        for (size_t byte=0;byte<8;++byte) output[8*static_cast<size_t>(i)+byte]=static_cast<uint8_t>(bits >> (8*byte));
    }
    return 8*n*m;
}
