#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_LENGTH=16, MAX_SUPPORT=17;
std::int64_t choose_value(int n,int k) {
    if(k<0||k>n) return 0;
    if(k>n-k) k=n-k;
    std::int64_t result=1;
    for(int i=1;i<=k;++i) result=result*(n-k+i)/i;
    return result;
}
std::int64_t gcd_value(std::int64_t a,std::int64_t b) { while(b){auto r=a%b;a=b;b=r;}return a; }
void put_i64(std::uint8_t *out,std::size_t word,std::int64_t value) {
    const auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t b=0;b<8;++b) out[word*8+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}
extern "C" std::int64_t spatial_motif_same_type_contact_pmf(
    const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) {
    if(input==nullptr||length!=3)return -1;
    const auto l0=input[0],x10=input[1],x20=input[2];
    if(l0<1||l0>MAX_LENGTH||x10<0||x10>l0||x20<0||x20>l0)return -1;
    const int l=static_cast<int>(l0),x1=static_cast<int>(x10),x2=static_cast<int>(x20);
    const int low=x1+x2>l?x1+x2-l:0,high=x1<x2?x1:x2;
    const auto denominator=choose_value(l,x2);
    std::int64_t numerators[MAX_SUPPORT]{};
    for(int i=low;i<=high;++i) numerators[i-low]=choose_value(x1,i)*choose_value(l-x1,x2-i);
    std::int64_t expected_num=static_cast<std::int64_t>(x1)*x2,expected_den=l;
    const auto divisor=gcd_value(expected_num,expected_den);expected_num/=divisor;expected_den/=divisor;
    const auto count=static_cast<std::size_t>(high-low+1),words=3+count+2,bytes=words*8;
    if(output==nullptr||capacity<bytes)return -2;
    put_i64(output,0,low);put_i64(output,1,high);put_i64(output,2,denominator);
    for(std::size_t i=0;i<count;++i)put_i64(output,3+i,numerators[i]);
    put_i64(output,3+count,expected_num);put_i64(output,4+count,expected_den);
    return static_cast<std::int64_t>(bytes);
}
