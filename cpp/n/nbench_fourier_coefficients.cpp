#include <cmath>
#include <cstddef>
#include <cstdint>
static constexpr std::int64_t INVALID=-1e300;
static double term(double x,double omega,int select){double base=std::pow(x+1.0,x);if(select==0)return base;if(select==1)return base*std::cos(omega*x);return base*std::sin(omega*x);}
static double integrate(double omega,int select){double x=0.0,dx=2.0/200.0,value=term(0.0,omega,select)/2.0;int steps=200;if(steps!=1){--steps;while(--steps){x+=dx;value+=term(x,omega,select);}}return(value+term(2.0,omega,select)/2.0)*dx;}
extern "C" double nbench_fourier_coefficients(const std::int64_t* input,std::size_t length){if(!input||length<1||length>2)return INVALID;auto raw=input[0];if(raw<1||raw>16||length!=1)return INVALID;auto n=static_cast<std::size_t>(raw);double a[16]{},b[16]{};a[0]=integrate(0.0,0)/2.0;for(std::size_t i=1;i<n;++i){double omega=3.1415926535897932*static_cast<double>(i);a[i]=integrate(omega,1);b[i]=integrate(omega,2);}double checksum=0.0;for(std::size_t i=0;i<n;++i)checksum+=static_cast<double>(i+1)*a[i];for(std::size_t i=1;i<n;++i)checksum+=static_cast<double>(i)*b[i];return std::isfinite(checksum)?checksum:INVALID;}
