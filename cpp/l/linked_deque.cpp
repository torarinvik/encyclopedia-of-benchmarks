#include <cstddef>
#include <cstdint>
extern "C" std::int64_t linked_deque(const std::int64_t*v,std::size_t n){if(!v||n<2||n>20||n%2)return -1;std::int64_t q[40]={};std::size_t h=16,t=16;std::int64_t out=0,place=1;for(std::size_t p=0;p<n;p+=2){auto op=v[p],a=v[p+1];if(op<0||op>6)return -1;if(op<2){if(a< -15||a>15)return -1;if(op==0)q[--h]=a;else q[t++]=a;continue;}if(a!=0)return -1;std::int64_t d=0;if(op==2){if(h<t)d=q[h++]+16;}else if(op==3){if(h<t)d=q[--t]+16;}else if(op==4){if(h<t)d=q[h]+16;}else if(op==5){if(h<t)d=q[t-1]+16;}else d=h==t?1:2;out+=d*place;place*=32;}return out;}
