#include <cstddef>
#include <cstdint>
extern "C" std::int64_t iterating_through_submasks(const std::int64_t*v,std::size_t n){if(!v||n!=1||v[0]<1||v[0]>4095)return -1;const auto mask=v[0];std::int64_t count=0,submask=mask;while(submask){++count;submask=(submask-1)&mask;}return count;}
