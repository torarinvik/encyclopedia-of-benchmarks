#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace { void put_f64_le(std::uint8_t *out,std::size_t offset,double value){std::uint64_t bits;std::memcpy(&bits,&value,8);for(std::size_t b=0;b<8;++b)out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));} }

extern "C" std::int64_t triangle(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) noexcept {
    if(!input||length!=6)return -1;
    for(std::size_t i=0;i<6;++i)if(input[i]<-100||input[i]>100)return -1;
    const double x1=input[0],y1=input[1],x2=input[2],y2=input[3],x3=input[4],y3=input[5];
    if(x1==x2||x1==x3||x2==x3||y3==y1||y3==y2)return -1;
    const double determinant=x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2);if(determinant==0.0)return -1;
    const double s1=x1*x1+y1*y1,s2=x2*x2+y2*y2,s3=x3*x3+y3*y3;
    const double circum_x=(s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2.0*determinant);
    const double circum_y=-(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2.0*determinant);
    const double side_a=std::hypot(x2-x3,y2-y3),side_b=std::hypot(x1-x3,y1-y3),side_c=std::hypot(x1-x2,y1-y2);
    const double perimeter=side_a+side_b+side_c;
    const double incenter_x=(side_a*x1+side_b*x2+side_c*x3)/perimeter,incenter_y=(side_a*y1+side_b*y2+side_c*y3)/perimeter;
    const double inv_m1=-(x3-x1)/(y3-y1),inv_m2=-(x3-x2)/(y3-y2),rhs1=inv_m2*x1-y1,rhs2=inv_m1*x2-y2,solve_det=inv_m1-inv_m2;
    if(solve_det==0.0)return -1;
    const double ortho_x=(-rhs1+rhs2)/solve_det,ortho_y=(inv_m2*rhs2-inv_m1*rhs1)/solve_det;
    if(capacity<48||!output)return -2;
    const double values[6]={circum_x,circum_y,incenter_x,incenter_y,ortho_x,ortho_y};
    for(std::size_t i=0;i<6;++i)put_f64_le(output,i*8,values[i]);
    return 48;
}
