#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t polynomial_discrete_antiderivative(const int64_t *input, size_t length,
                                                       uint8_t *output, size_t capacity) {
    constexpr int64_t p=998244353;
    if (!input || length<2 || length>33 || input[0]<1 || input[0]>32) return -1;
    int n=static_cast<int>(input[0]);
    if (length!=static_cast<size_t>(n+1)) return -1;
    for (int i=0; i<n; ++i) if (input[1+i]<0 || input[1+i]>=p) return -1;
    if (!output || capacity<8*static_cast<size_t>(n+1)) return -2;
    std::array<std::array<int64_t,33>,33> choose{};
    std::array<int64_t,33> inverse{}, g{};
    choose[0][0]=1;
    for (int k=1; k<=n; ++k) {
        choose[k][0]=choose[k][k]=1;
        for (int j=1; j<k; ++j) choose[k][j]=(choose[k-1][j-1]+choose[k-1][j])%p;
    }
    inverse[1]=1;
    for (int k=2; k<=n; ++k) inverse[k]=p-(p/k)*inverse[p%k]%p;
    for (int j=n-1; j>=0; --j) {
        int64_t sum=0;
        for (int k=j+2; k<=n; ++k) sum=(sum+choose[k][j]*g[k])%p;
        g[j+1]=((input[1+j]-sum+p)%p)*inverse[j+1]%p;
    }
    for (int i=0; i<=n; ++i) {
        auto bits=static_cast<uint64_t>(g[i]);
        for (size_t byte=0; byte<8; ++byte) output[8*static_cast<size_t>(i)+byte]=static_cast<uint8_t>(bits >> (8*byte));
    }
    return 8*(n+1);
}
