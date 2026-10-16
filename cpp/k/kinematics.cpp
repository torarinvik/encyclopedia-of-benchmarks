#include <cstddef>
#include <cstdint>
extern "C" std::int64_t kinematics(const std::int64_t*v,std::size_t n){if(!v||n!=4)return -1;auto o=v[0],x=v[1],y=v[2],z=v[3];if(o<0||o>3||x< -1000||x>1000||y< -1000||y>1000||z< -1000||z>1000)return -1;if(o==0)return 2*x+2*y*z;if(o==1)return 2*x*z+y*z*z;if(o==2)return 2*x*x+4*y*z;return (x+y)*z;}
