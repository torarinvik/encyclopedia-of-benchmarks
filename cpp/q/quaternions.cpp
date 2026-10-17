#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t quaternions(const double *input, std::size_t length, double *output, std::size_t output_capacity) noexcept {
    if (!input || length < 1 || length > 10) return -1;
    for (std::size_t i=0;i<length;++i) if (!std::isfinite(input[i])) return -1;
    const double op=input[0]; if (op!=0.0 && op!=1.0 && op!=2.0) return -1;
    const int operation=static_cast<int>(op); const std::size_t expected=operation==0?4:operation==1?5:9;
    const std::size_t count=operation==1?3:4; if(length!=expected)return -1;
    float v[8];
    if(operation==0){for(std::size_t i=1;i<4;++i){if(input[i]<-3.0||input[i]>3.0)return -1;v[i-1]=static_cast<float>(input[i]);}}
    else if(operation==1){for(std::size_t i=1;i<5;++i){v[i-1]=static_cast<float>(input[i]);if(v[i-1]<-1.0f||v[i-1]>1.0f)return -1;}
        const float w=v[0],q1=v[1],q2=v[2],q3=v[3];float norm=w*w;norm=norm+q1*q1;norm=norm+q2*q2;norm=norm+q3*q3;if(std::fabs(norm-1.0f)>1e-6f)return -1;float pa=w*q2+q1*q3;pa=2.0f*pa;if(pa < -1.0f||pa>1.0f)return -1;}
    else {for(std::size_t i=1;i<9;++i){if(input[i]<-1.0||input[i]>1.0)return -1;v[i-1]=static_cast<float>(input[i]);}}
    if(!output||output_capacity<count)return -2;
    float r[4];
    if(operation==0){const float yaw=v[0],pitch=v[1],roll=v[2];const float cy=std::cos(yaw*0.5f),sy=std::sin(yaw*0.5f),cp=std::cos(pitch*0.5f),sp=std::sin(pitch*0.5f),cr=std::cos(roll*0.5f),sr=std::sin(roll*0.5f);r[0]=(cr*cp)*cy+(sr*sp)*sy;r[1]=(sr*cp)*cy-(cr*sp)*sy;r[2]=(cr*sp)*cy+(sr*cp)*sy;r[3]=(cr*cp)*sy-(sr*sp)*cy;}
    else if(operation==1){const float w=v[0],q1=v[1],q2=v[2],q3=v[3];const float ry=2.0f*(w*q1+q2*q3),rx=1.0f-2.0f*(q1*q1+q2*q2),p=std::asin(2.0f*(w*q2+q1*q3)),yy=2.0f*(w*q3+q1*q2),yx=1.0f-2.0f*(q2*q2+q3*q3);r[0]=std::atan2(ry,rx);r[1]=p;r[2]=std::atan2(yy,yx);}
    else{const float aw=v[0],a1=v[1],a2=v[2],a3=v[3],bw=v[4],b1=v[5],b2=v[6],b3=v[7];r[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;r[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;r[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;r[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw;}
    for(std::size_t i=0;i<count;++i)output[i]=static_cast<double>(r[i]);return static_cast<std::int64_t>(count);
}
