#include <cstddef>
#include <cstdint>
extern "C" std::int64_t paranthesis_matching(const std::int64_t*v,std::size_t n)noexcept{if(!v||n<2||n>100)return -1;auto count=v[0];if(count<1||count>99||n!=static_cast<std::size_t>(count)+1)return -1;char st[99];std::size_t sp=0;for(std::size_t i=1;i<n;i++){auto x=v[i];if(x<33||x>126)return -1;if(x=='('||x=='{'||x=='['||x=='<')st[sp++]=static_cast<char>(x);else if(x==')'||x=='}'||x==']'||x=='>'){char want=x==')'?'(':x=='}'?'{':x==']'?'[':'<';if(!sp||st[--sp]!=want)return 0;}else return 0;}return sp==0;}
