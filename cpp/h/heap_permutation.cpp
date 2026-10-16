#include <cstddef>
#include <cstdint>

constexpr std::size_t MAX_LENGTH=7, BYTES_PER_VALUE=4;
static void store_i32(std::uint8_t* out,std::size_t off,std::int32_t v){auto bits=static_cast<std::uint32_t>(v);for(std::size_t b=0;b<4;++b)out[off+b]=static_cast<std::uint8_t>(bits>>(8*b));}
static void generate(std::int32_t* values,std::size_t n,std::size_t k,std::uint8_t* out,std::size_t* rows){
    if(k==1){auto start=*rows*n*BYTES_PER_VALUE;for(std::size_t j=0;j<n;++j)store_i32(out,start+j*BYTES_PER_VALUE,values[j]);++*rows;return;}
    for(std::size_t i=0;i<k;++i){auto s=k%2==0?i:0;auto tmp=values[s];values[s]=values[k-1];values[k-1]=tmp;generate(values,n,k-1,out,rows);}
}
extern "C" std::int64_t heap_permutation(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept{
    if(!input||length<1||length>MAX_LENGTH+1)return -1;auto nv=input[0];if(nv<0||nv>static_cast<std::int64_t>(MAX_LENGTH)||length!=static_cast<std::size_t>(nv)+1)return -1;auto n=static_cast<std::size_t>(nv);
    std::int32_t values[MAX_LENGTH];for(std::size_t i=0;i<n;++i){auto v=input[i+1];if(v<INT32_MIN||v>INT32_MAX)return -1;values[i]=static_cast<std::int32_t>(v);}
    std::size_t permutations=1;for(std::size_t f=2;f<=n;++f)permutations*=f;auto required=permutations*n*BYTES_PER_VALUE;if(capacity<required||(required!=0&&!output))return -2;if(n==0)return 1;std::size_t rows=0;generate(values,n,n,output,&rows);return static_cast<std::int64_t>(rows);
}
