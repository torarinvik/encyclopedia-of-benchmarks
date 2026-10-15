#include <cmath>

namespace {
constexpr double epsilon=1.0e-7,min_width=2.0e-7,pi=3.14159265358979323846;
double objective(int id,double x){return id==0?(x-2.0)*(x-2.0):std::cos(x);}
}
extern "C" double golden_search_extrema(double objective_id,double left,double right) noexcept {
    if(objective_id!=0.0&&objective_id!=1.0)return -1.0;
    if(objective_id==0.0&&(!(left>=0.0&&left<=4.0)||!(right>=0.0&&right<=4.0)))return -1.0;
    if(objective_id==1.0&&(!(left>=2.0&&left<=4.0)||!(right>=2.0&&right<=4.0)))return -1.0;
    double a=left,b=right;if(a>b){double t=a;a=b;b=t;}
    if(b-a<min_width||(objective_id==0.0?!(a<2.0&&2.0<b):!(a<pi&&pi<b)))return -1.0;
    double mean=INFINITY,previous_mean=INFINITY;const double phi=1.61803400516510009765625;
    for(int i=0;i<128&&std::abs(b-a)>epsilon;++i){previous_mean=mean;const double ratio=(b-a)/phi,c=b-ratio,d=a+ratio;if(objective(static_cast<int>(objective_id),c)<objective(static_cast<int>(objective_id),d))b=d;else a=c;mean=(a+b)/2.0;}
    return previous_mean;
}
