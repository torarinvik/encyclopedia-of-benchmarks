#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text=4096, max_pattern=128, tables=130, max_input=4227;

std::int64_t preprocess(const std::int64_t* pattern,std::size_t m,
                        std::int64_t* order,std::int64_t* next,std::int64_t* shift) noexcept {
    std::array<std::int64_t,tables> hmax{},kmin{},prefix{},rmin{};
    std::int64_t i=1,k=1;
    while(static_cast<std::size_t>(k)<=m) {
        while(pattern[i]==pattern[i-k]) ++i;
        hmax[static_cast<std::size_t>(k)]=i;
        std::int64_t q=k+1;
        while(hmax[static_cast<std::size_t>(q-k)]+k<i) {
            hmax[static_cast<std::size_t>(q)]=hmax[static_cast<std::size_t>(q-k)]+k; ++q;
        }
        k=q;
        if(k==i+1) i=k;
    }
    for(i=static_cast<std::int64_t>(m);i>=1;--i)
        if(static_cast<std::size_t>(hmax[static_cast<std::size_t>(i)])<m)
            kmin[static_cast<std::size_t>(hmax[static_cast<std::size_t>(i)])]=i;
    std::int64_t r=static_cast<std::int64_t>(m);
    for(i=static_cast<std::int64_t>(m)-1;i>=0;--i) {
        if(static_cast<std::size_t>(hmax[static_cast<std::size_t>(i+1)])==m) r=i+1;
        if(kmin[static_cast<std::size_t>(i)]==0) rmin[static_cast<std::size_t>(i)]=r;
    }
    std::int64_t split=-1; r=static_cast<std::int64_t>(m);
    for(i=0;static_cast<std::size_t>(i)<m;++i) {
        if(kmin[static_cast<std::size_t>(i)]==0) order[--r]=i;
        else order[++split]=i;
    }
    const auto nd=split;
    for(i=0;i<=nd;++i) shift[i]=kmin[static_cast<std::size_t>(order[i])];
    for(i=nd+1;static_cast<std::size_t>(i)<m;++i) shift[i]=rmin[static_cast<std::size_t>(order[i])];
    shift[m]=rmin[0];
    std::int64_t count=0;
    for(i=0;static_cast<std::size_t>(i)<m;++i) {
        prefix[static_cast<std::size_t>(i)]=count;
        if(kmin[static_cast<std::size_t>(i)]>0) ++count;
    }
    for(i=0;i<=nd;++i) next[i]=prefix[static_cast<std::size_t>(order[i]-kmin[static_cast<std::size_t>(order[i])])];
    for(i=nd+1;static_cast<std::size_t>(i)<m;++i)
        next[i]=prefix[m-static_cast<std::size_t>(rmin[static_cast<std::size_t>(order[i])])];
    next[m]=prefix[m-static_cast<std::size_t>(rmin[static_cast<std::size_t>(order[m-1])])];
    return nd;
}

std::int64_t search(const std::array<std::int64_t,max_text>& text,std::size_t n,
                    const std::array<std::int64_t,tables>& pattern,std::size_t m) noexcept {
    std::size_t ell=0;
    while(ell+1<m && pattern[ell+1]==pattern[0]) ++ell;
    std::int64_t matches=0,sum=0,xor_sum=0;
    if(ell==m-1) {
        std::size_t run=0;
        for(std::size_t pos=0;pos<n;++pos) {
            run=text[pos]==pattern[0]?run+1:0;
            if(run>=m) { const auto start=static_cast<std::int64_t>(pos+1-m); ++matches; sum+=start; xor_sum^=start; }
        }
        return (matches<<36)|(sum<<12)|xor_sum;
    }
    std::array<std::int64_t,tables> order{},next{},shift{};
    const auto nd=preprocess(pattern.data(),m,order.data(),next.data(),shift.data());
    if(n<m) return 0;
    std::int64_t i=0,j=0,last=-1;
    bool heavy=false;
    while(static_cast<std::size_t>(j)<=n-m) {
        if(heavy && i==0) {
            std::int64_t k=last-j+1;
            while(static_cast<std::size_t>(j+k)<n && pattern[0]==text[static_cast<std::size_t>(j+k)]) ++k;
            if(static_cast<std::size_t>(k)<=ell || static_cast<std::size_t>(j+k)>=n ||
               pattern[ell+1]!=text[static_cast<std::size_t>(j+k)]) {
                i=0; j+=k+1; last=j-1;
            } else {
                i=1; last=j+k; j=last-static_cast<std::int64_t>(ell+1);
            }
        } else {
            while(static_cast<std::size_t>(i)<m && last<j+order[static_cast<std::size_t>(i)] &&
                  pattern[static_cast<std::size_t>(order[static_cast<std::size_t>(i)])]==
                  text[static_cast<std::size_t>(j+order[static_cast<std::size_t>(i)])]) ++i;
            if(static_cast<std::size_t>(i)>=m || last>=j+order[static_cast<std::size_t>(i)]) {
                ++matches; sum+=j; xor_sum^=j; i=static_cast<std::int64_t>(m);
            }
            if(i>nd) last=j+static_cast<std::int64_t>(m)-1;
            j+=shift[static_cast<std::size_t>(i)]; i=next[static_cast<std::size_t>(i)];
        }
        heavy=j<=last;
    }
    return (matches<<36)|(sum<<12)|xor_sum;
}
}

extern "C" std::int64_t galil_giancarlo_search(const std::int64_t* input,std::size_t length) noexcept {
    if(input==nullptr || length<2 || length>max_input) return -1;
    const auto nv=input[0],mv=input[1];
    if(nv<0 || nv>static_cast<std::int64_t>(max_text) || mv<1 || mv>static_cast<std::int64_t>(max_pattern)) return -1;
    const auto n=static_cast<std::size_t>(nv),m=static_cast<std::size_t>(mv);
    if(length!=2+n+m) return -1;
    std::array<std::int64_t,max_text> text{};
    std::array<std::int64_t,tables> pattern{};
    for(std::size_t i=0;i<n;++i) { if(input[2+i]<0 || input[2+i]>3) return -1; text[i]=input[2+i]; }
    for(std::size_t i=0;i<m;++i) { const auto c=input[2+n+i]; if(c<0 || c>3) return -1; pattern[i]=c; }
    pattern[m]=4;
    return search(text,n,pattern,m);
}
