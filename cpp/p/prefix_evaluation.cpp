#include <cstddef>
#include <cstdint>
static constexpr double INVALID=-1e300;
static bool op(int c){return c=='+'||c=='-'||c=='*'||c=='/';}
extern "C" double prefix_evaluation(const std::int64_t*v,std::size_t n) noexcept{if(!v||n<2||n>63||v[0]<1||v[0]>62||n!=std::size_t(v[0])+1)return INVALID;char tokens[31];std::size_t count=0;bool need=true;for(std::size_t i=1;i<n;i++){if(v[i]<0||v[i]>127)return INVALID;int c=int(v[i]);if(c==' '){if(need)return INVALID;need=true;continue;}if(!(op(c)||(c>='0'&&c<='9'))||!need||count>=31)return INVALID;tokens[count++]=char(c);need=false;}if(need||count==0)return INVALID;double stack[31];std::size_t top=0;for(std::size_t p=count;p>0;p--){int c=tokens[p-1];if(c>='0'&&c<='9'){stack[top++]=double(c-'0');continue;}if(top<2)return INVALID;double a=stack[--top],b=stack[--top];if(c=='+')stack[top++]=a+b;else if(c=='-')stack[top++]=a-b;else if(c=='*')stack[top++]=a*b;else{if(b==0.0)return INVALID;stack[top++]=a/b;}}return top==1?stack[0]:INVALID;}
