#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_length = 4096;
bool punctuation(std::int64_t v) noexcept { return (v>=33&&v<=47)||(v>=58&&v<=64)||(v>=91&&v<=96)||(v>=123&&v<=126); }
int fold(std::int64_t v) noexcept { return v>='A'&&v<='Z'?static_cast<int>(v+32):static_cast<int>(v); }
}
extern "C" std::int64_t findpalindrome(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (length>max_length||(length&&input==nullptr)) return -1;
    for(std::size_t i=0;i<length;++i) if(input[i]<32||input[i]>126) return -1;
    std::size_t written=0, segment=0; bool found=false;
    for(std::size_t end=0;end<=length;++end){
        if(end<length&&input[end]!=32) continue;
        std::size_t token_length=0; for(std::size_t i=segment;i<end;++i) if(!punctuation(input[i])) ++token_length;
        std::size_t left=segment,right=end;
        while(left<right){while(left<right&&punctuation(input[left]))++left;while(left<right&&punctuation(input[right-1]))--right;
            if(left>=right)break; if(fold(input[left])!=fold(input[right-1])){token_length=0;break;} ++left;--right;}
        if(token_length>1){ if(written+(found?1:0)+token_length>capacity)return -2; if(found)output[written++]=0;
            for(std::size_t i=segment;i<end;++i)if(!punctuation(input[i]))output[written++]=static_cast<std::uint8_t>(input[i]); found=true; }
        segment=end+1;
    }
    return static_cast<std::int64_t>(written);
}
