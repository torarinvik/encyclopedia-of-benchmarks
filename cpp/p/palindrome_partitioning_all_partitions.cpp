#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH=12, OUT_I64_CAP=16000;
struct Context { const std::int64_t* text; std::size_t length; std::size_t ends[MAX_LENGTH]; std::int64_t packed[OUT_I64_CAP]; std::size_t used, partitions; };
bool is_palindrome(const Context& ctx,std::size_t start,std::size_t end){while(start<end){if(ctx.text[start]!=ctx.text[end-1])return false;++start;--end;}return true;}
void enumerate(Context&ctx,std::size_t start,std::size_t depth){if(start==ctx.length){++ctx.partitions;ctx.packed[ctx.used++]=static_cast<std::int64_t>(depth);for(std::size_t i=0;i<depth;++i)ctx.packed[ctx.used++]=static_cast<std::int64_t>(ctx.ends[i]);return;}for(std::size_t end=start+1;end<=ctx.length;++end)if(is_palindrome(ctx,start,end)){ctx.ends[depth]=end;enumerate(ctx,end,depth+1);}}
}
extern "C" std::int64_t palindrome_partitioning_all_partitions(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept{
 if(input==nullptr||length<1||input[0]<0||input[0]>static_cast<std::int64_t>(MAX_LENGTH)||length!=static_cast<std::size_t>(input[0])+1)return -1;
 const std::size_t n=static_cast<std::size_t>(input[0]);for(std::size_t i=0;i<n;++i)if(input[i+1]<0||input[i+1]>127)return -1;
 Context ctx{};ctx.text=input+1;ctx.length=n;ctx.used=1;enumerate(ctx,0,0);ctx.packed[0]=static_cast<std::int64_t>(ctx.partitions);
 const std::size_t required=ctx.used*8;if(output==nullptr||capacity<required)return -2;
 for(std::size_t i=0;i<ctx.used;++i){const std::uint64_t bits=static_cast<std::uint64_t>(ctx.packed[i]);for(std::size_t byte=0;byte<8;++byte)output[i*8+byte]=static_cast<std::uint8_t>(bits>>(byte*8));}
 return static_cast<std::int64_t>(required);
}
