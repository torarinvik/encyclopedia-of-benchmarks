/*
 * C Converted Whetstone Double Precision Benchmark
 *		Version 1.2	22 March 1998
 *
 *		(c) Copyright 1998 Painter Engineering, Inc.
 *		All Rights Reserved.
 *
 *		Permission is granted to use, duplicate, and
 *		publish this text and program as long as it
 *		includes this entire comment block and limited
 *		rights reference.
 *
 * Converted by Rich Painter, Painter Engineering, Inc. based on the
 * www.netlib.org benchmark/whetstoned version obtained 16 March 1998.
 *
 * A novel approach was used here to keep the look and feel of the
 * FORTRAN version.  Altering the FORTRAN-based array indices,
 * starting at element 1, to start at element 0 for C, would require
 * numerous changes, including decrementing the variable indices by 1.
 * Instead, the array E1[] was declared 1 element larger in C.  This
 * allows the FORTRAN index range to function without any literal or
 * variable indices changes.  The array element E1[0] is simply never
 * used and does not alter the benchmark results.
 *
 * The major FORTRAN comment blocks were retained to minimize
 * differences between versions.  Modules N5 and N12, like in the
 * FORTRAN version, have been eliminated here.
 *
 * An optional command-line argument has been provided [-c] to
 * offer continuous repetition of the entire benchmark.
 * An optional argument for setting an alternate LOOP count is also
 * provided.  Define PRINTOUT to cause the POUT() function to print
 * outputs at various stages.  Final timing measurements should be
 * made with the PRINTOUT undefined.
 *
 * Questions and comments may be directed to the author at
 *			r.painter@ieee.org
 */

#include <cmath>
#include <cstddef>
#include <cstdint>
namespace {
constexpr double invalid_result=-1e300;
void pa(double e[5],double t){int j=0;do{e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])/2.0;++j;}while(j<6);}
double p3(double x,double y){double x1=x,y1=y;x1=0.499975*(x1+y1);y1=0.499975*(x1+y1);return(x1+y1)/2.0;}
double one_pass(){const double t=0.499975,t1=0.50025,t2=2.0;double sum=0.0;std::int64_t idx=1;
#define INCLUDE(v) do{sum+=double(idx)*(v);++idx;}while(0)
 double x1=1.0,x2=-1.0,x3=-1.0,x4=-1.0;INCLUDE(x1);INCLUDE(x2);INCLUDE(x3);INCLUDE(x4);
 double e[5]={0.0,1.0,-1.0,-1.0,-1.0};for(std::int64_t i=0;i<12;++i){e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])*t;}INCLUDE(e[1]);INCLUDE(e[2]);INCLUDE(e[3]);INCLUDE(e[4]);
 for(int i=0;i<14;++i)pa(e,t);INCLUDE(e[1]);INCLUDE(e[2]);INCLUDE(e[3]);INCLUDE(e[4]);
 std::int64_t j=1;for(int i=0;i<345;++i){j=j==1?2:3;j=j>2?0:1;j=j<1?1:0;}INCLUDE(double(j));
 j=1;std::int64_t k=2,l=3;for(int i=0;i<210;++i){j=j*(k-j)*(l-k);k=l*k-(l-j)*k;l=(l-k)*(k+j);e[l-1]=double(j+k+l);e[k-1]=double(j*k*l);}INCLUDE(double(j));INCLUDE(double(k));INCLUDE(double(l));INCLUDE(e[1]);INCLUDE(e[2]);INCLUDE(e[3]);INCLUDE(e[4]);
 double x=0.5,y=0.5;for(int i=0;i<32;++i){x=t*std::atan(t2*std::sin(x)*std::cos(x)/(std::cos(x+y)+std::cos(x-y)-1.0));y=t*std::atan(t2*std::sin(y)*std::cos(y)/(std::cos(x+y)+std::cos(x-y)-1.0));}INCLUDE(x);INCLUDE(y);
 x=1.0;y=1.0;double z=1.0;for(int i=0;i<899;++i)z=p3(x,y);INCLUDE(x);INCLUDE(y);INCLUDE(z);
 j=1;k=2;l=3;e[1]=1.0;e[2]=2.0;e[3]=3.0;for(int i=0;i<616;++i){e[j]=e[k];e[k]=e[l];e[l]=e[j];}INCLUDE(double(j));INCLUDE(double(k));INCLUDE(double(l));INCLUDE(e[1]);INCLUDE(e[2]);INCLUDE(e[3]);INCLUDE(e[4]);
 j=2;k=3;INCLUDE(double(j));INCLUDE(double(k));x=0.75;for(int i=0;i<93;++i)x=std::sqrt(std::exp(std::log(x)/t1));INCLUDE(x);
#undef INCLUDE
 return sum;}
}
extern "C" double ansibench_whetstone(const std::int64_t*values,std::size_t length){if(!values||length!=1||values[0]<1||values[0]>3)return invalid_result;double total=0.0;for(std::int64_t pass=0;pass<values[0];++pass)total+=double(pass+1)*one_pass();return std::isfinite(total)?total:invalid_result;}
