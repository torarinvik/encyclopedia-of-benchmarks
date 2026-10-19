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

module ansibench_whetstone;
const double INVALID_RESULT = -1e300;
fn void pa(double* e,double t){int j=0;do{e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])/2.0;j++;}while(j<6);}
fn double p3(double x,double y){double x1=x,y1=y;x1=0.499975*(x1+y1);y1=0.499975*(x1+y1);return(x1+y1)/2.0;}
fn void add(double* sum,double* idx,double value){*sum+=*idx*value;*idx+=1.0;}
fn double one_pass(){double t=0.499975,t1=0.50025,t2=2.0,sum=0.0,idx=1.0;add(&sum,&idx,1.0);add(&sum,&idx,-1.0);add(&sum,&idx,-1.0);add(&sum,&idx,-1.0);
 double[5] e={0.0,1.0,-1.0,-1.0,-1.0};for(int i=0;i<12;i++){e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])*t;}for(int i=1;i<=4;i++)add(&sum,&idx,e[i]);
 for(int i=0;i<14;i++)pa(&e[0],t);for(int i=1;i<=4;i++)add(&sum,&idx,e[i]);
 long j=1;for(int i=0;i<345;i++){j=j==1?2:3;j=j>2?0:1;j=j<1?1:0;}add(&sum,&idx,(double)j);
 j=1;long k=2,l=3;for(int i=0;i<210;i++){j=j*(k-j)*(l-k);k=l*k-(l-j)*k;l=(l-k)*(k+j);e[l-1]=(double)(j+k+l);e[k-1]=(double)(j*k*l);}add(&sum,&idx,(double)j);add(&sum,&idx,(double)k);add(&sum,&idx,(double)l);for(int i=1;i<=4;i++)add(&sum,&idx,e[i]);
 double x=0.5,y=0.5;for(int i=0;i<32;i++){x=t*math.atan(t2*math.sin(x)*math.cos(x)/(math.cos(x+y)+math.cos(x-y)-1.0));y=t*math.atan(t2*math.sin(y)*math.cos(y)/(math.cos(x+y)+math.cos(x-y)-1.0));}add(&sum,&idx,x);add(&sum,&idx,y);
 x=1.0;y=1.0;double z=1.0;for(int i=0;i<899;i++)z=p3(x,y);add(&sum,&idx,x);add(&sum,&idx,y);add(&sum,&idx,z);
 j=1;k=2;l=3;e[1]=1.0;e[2]=2.0;e[3]=3.0;for(int i=0;i<616;i++){e[j]=e[k];e[k]=e[l];e[l]=e[j];}add(&sum,&idx,(double)j);add(&sum,&idx,(double)k);add(&sum,&idx,(double)l);for(int i=1;i<=4;i++)add(&sum,&idx,e[i]);
 j=2;k=3;add(&sum,&idx,(double)j);add(&sum,&idx,(double)k);x=0.75;for(int i=0;i<93;i++)x=math.sqrt(math.exp(math.log(x)/t1));add(&sum,&idx,x);return sum;}
fn double ansibench_whetstone(long* values,usz length) @export("ansibench_whetstone"){
 if(values==null||length!=1||values[0]<1||values[0]>3)return INVALID_RESULT;double total=0.0;for(long pass=0;pass<values[0];pass++)total+=(double)(pass+1)*one_pass();if(total!=total||total>=1e300||total<=-1e300)return INVALID_RESULT;return total;
}
