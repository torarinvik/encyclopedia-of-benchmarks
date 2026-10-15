#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length=256; }
extern "C" std::int64_t longest_common_substring(const std::int64_t* input,std::size_t length) noexcept {
    if(!input||length<2||input[0]<0||input[0]>static_cast<std::int64_t>(max_length))return -1;
    const auto first_length=static_cast<std::size_t>(input[0]);
    if(first_length+2>length||input[first_length+1]<0||input[first_length+1]>static_cast<std::int64_t>(max_length))return -1;
    const auto second_length=static_cast<std::size_t>(input[first_length+1]);if(length!=first_length+second_length+2)return -1;
    const auto* first=input+1;const auto* second=input+first_length+2;
    for(std::size_t i=0;i<first_length;++i)if(first[i]<32||first[i]>126)return -1;
    for(std::size_t i=0;i<second_length;++i)if(second[i]<32||second[i]>126)return -1;
    std::array<std::int64_t,max_length+1> dp{};std::int64_t best=0;
    for(std::size_t i=1;i<=first_length;++i)for(std::size_t j=second_length;j>0;--j){if(first[i-1]==second[j-1]){dp[j]=dp[j-1]+1;if(dp[j]>best)best=dp[j];}else dp[j]=0;}
    return best;
}
