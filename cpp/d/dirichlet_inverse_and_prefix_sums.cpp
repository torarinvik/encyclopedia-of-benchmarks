#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

static constexpr int64_t modulus=998244353;
static int64_t power(int64_t base, int64_t exponent) {
    int64_t result=1;
    while (exponent) {
        if (exponent&1) result=result*base%modulus;
        base=base*base%modulus; exponent>>=1;
    }
    return result;
}
static int locate(const std::vector<int>& q, int value) {
    auto it=std::lower_bound(q.begin(),q.end(),value);
    return it!=q.end() && *it==value ? static_cast<int>(it-q.begin()) : -1;
}
extern "C" int64_t dirichlet_inverse_and_prefix_sums(const int64_t *input, size_t length,
                                                      uint8_t *output, size_t capacity) {
    if (!input || length<2 || length>16 || input[0]<1 || input[0]>64) return -1;
    int n=static_cast<int>(input[0]);
    std::vector<int> q;
    for (int i=n; i>=1; --i) {
        int value=n/i;
        if (q.empty() || q.back()!=value) q.push_back(value);
    }
    if (length!=1+q.size() || input[1]==0) return -1;
    for (size_t i=1; i<length; ++i) if (input[i]<0 || input[i]>=modulus) return -1;
    if (!output || capacity<8*q.size()) return -2;
    const int64_t inverse=power(input[1],modulus-2);
    std::vector<int64_t> g(q.size());
    for (size_t i=0; i<q.size(); ++i) {
        int x=q[i], left=2;
        int64_t total=0;
        while (left<=x) {
            int quotient=x/left, right=x/quotient;
            int hi=locate(q,right), lo=locate(q,left-1), gi=locate(q,quotient);
            if (hi<0 || lo<0 || gi<0) return -1;
            int64_t interval=(input[1+hi]-input[1+lo]+modulus)%modulus;
            total=(total+interval*g[gi])%modulus;
            left=right+1;
        }
        g[i]=((1-total+modulus)%modulus)*inverse%modulus;
    }
    for (size_t i=0; i<g.size(); ++i) {
        uint64_t bits=static_cast<uint64_t>(g[i]);
        for (size_t byte=0; byte<8; ++byte) output[8*i+byte]=static_cast<uint8_t>(bits >> (8*byte));
    }
    return static_cast<int64_t>(8*g.size());
}
