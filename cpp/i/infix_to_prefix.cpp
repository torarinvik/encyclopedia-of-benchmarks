/* Convert fully parenthesized bounded ASCII infix expressions to prefix. */
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t kMax = 256;
bool operand(std::int64_t c) noexcept { return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'); }
bool operation(std::int64_t c) noexcept { return c == '+' || c == '-' || c == '*' || c == '/' || c == '^'; }
int precedence(std::int64_t c) noexcept { return c == '+' || c == '-' ? 1 : (c == '*' || c == '/' ? 2 : 3); }
bool valid(const std::int64_t *in, std::size_t n) noexcept {
    unsigned char stage[kMax]; std::size_t depth=0; bool done=false;
    for (std::size_t i=0;i<n;++i) { auto ch=in[i];
        if(depth==0){ if(done)return false; if(operand(ch))done=true; else if(ch=='(')stage[depth++]=0; else return false; }
        else if(stage[depth-1]==0||stage[depth-1]==2){ if(operand(ch))stage[depth-1]=stage[depth-1]==0?1:3; else if(ch=='('&&depth<kMax)stage[depth++]=0; else return false; }
        else if(stage[depth-1]==1){ if(!operation(ch))return false; stage[depth-1]=2; }
        else { if(ch!=')')return false; --depth; if(depth==0)done=true; else if(stage[depth-1]==0)stage[depth-1]=1; else if(stage[depth-1]==2)stage[depth-1]=3; else return false; }
    }
    return depth==0&&done;
}
}
extern "C" std::int64_t infix_to_prefix(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) noexcept {
    if(length>kMax||(length&&input==nullptr))return -1; if(!length)return 0; if(!valid(input,length))return -1;
    std::uint8_t stack[kMax],postfix[kMax]; std::size_t top=0,count=0;
    for(std::size_t i=length;i>0;--i){auto ch=input[i-1]; if(operand(ch))postfix[count++]=static_cast<std::uint8_t>(ch);
        else if(ch==')')stack[top++]=')'; else if(ch=='('){while(top&&stack[top-1]!=')')postfix[count++]=stack[--top];if(top)--top;}
        else {while(top&&stack[top-1]!=')'&&precedence(ch)<precedence(stack[top-1]))postfix[count++]=stack[--top];stack[top++]=static_cast<std::uint8_t>(ch);}}
    while(top)postfix[count++]=stack[--top]; if(capacity<count||(count&&!output))return -2;
    for(std::size_t i=0;i<count;++i)output[i]=postfix[count-1-i]; return static_cast<std::int64_t>(count);
}
