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

package ansibench_whetstone
import "core:c"
import "core:math"

INVALID_RESULT :: -1e300
pa :: proc(e:^[5]f64,t:f64){j:=0;for{e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])/2.0;j+=1;if j>=6{break}}}
p3 :: proc(x,y:f64)->f64{x1:=x;y1:=y;x1=0.499975*(x1+y1);y1=0.499975*(x1+y1);return(x1+y1)/2.0}
include_value :: proc(sum,idx:^f64,value:f64){sum^+=idx^*value;idx^+=1.0}
one_pass :: proc()->f64{
 t:=0.499975;t1:=0.50025;t2:=2.0;sum:=0.0;idx:=1.0
 x1:=1.0;x2:=-1.0;x3:=-1.0;x4:=-1.0;include_value(&sum,&idx,x1);include_value(&sum,&idx,x2);include_value(&sum,&idx,x3);include_value(&sum,&idx,x4)
 e:=[5]f64{0,1,-1,-1,-1};for _ in 0..<12{e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])*t};include_value(&sum,&idx,e[1]);include_value(&sum,&idx,e[2]);include_value(&sum,&idx,e[3]);include_value(&sum,&idx,e[4])
 for _ in 0..<14{pa(&e,t)};include_value(&sum,&idx,e[1]);include_value(&sum,&idx,e[2]);include_value(&sum,&idx,e[3]);include_value(&sum,&idx,e[4])
 j:=1;for _ in 0..<345{if j==1{j=2}else{j=3};if j>2{j=0}else{j=1};if j<1{j=1}else{j=0}};include_value(&sum,&idx,f64(j))
 j=1;k:=2;l:=3;for _ in 0..<210{j=j*(k-j)*(l-k);k=l*k-(l-j)*k;l=(l-k)*(k+j);e[l-1]=f64(j+k+l);e[k-1]=f64(j*k*l)};include_value(&sum,&idx,f64(j));include_value(&sum,&idx,f64(k));include_value(&sum,&idx,f64(l));include_value(&sum,&idx,e[1]);include_value(&sum,&idx,e[2]);include_value(&sum,&idx,e[3]);include_value(&sum,&idx,e[4])
 x:=0.5;y:=0.5;for _ in 0..<32{x=t*math.atan(t2*math.sin(x)*math.cos(x)/(math.cos(x+y)+math.cos(x-y)-1.0));y=t*math.atan(t2*math.sin(y)*math.cos(y)/(math.cos(x+y)+math.cos(x-y)-1.0))};include_value(&sum,&idx,x);include_value(&sum,&idx,y)
 x=1.0;y=1.0;z:=1.0;for _ in 0..<899{z=p3(x,y)};include_value(&sum,&idx,x);include_value(&sum,&idx,y);include_value(&sum,&idx,z)
 j=1;k=2;l=3;e[1]=1.0;e[2]=2.0;e[3]=3.0;for _ in 0..<616{e[j]=e[k];e[k]=e[l];e[l]=e[j]};include_value(&sum,&idx,f64(j));include_value(&sum,&idx,f64(k));include_value(&sum,&idx,f64(l));include_value(&sum,&idx,e[1]);include_value(&sum,&idx,e[2]);include_value(&sum,&idx,e[3]);include_value(&sum,&idx,e[4])
 j=2;k=3;include_value(&sum,&idx,f64(j));include_value(&sum,&idx,f64(k));x=0.75;for _ in 0..<93{x=math.sqrt(math.exp(math.log(x)/t1))};include_value(&sum,&idx,x);return sum
}
@(export)
ansibench_whetstone::proc "c"(values:[^]i64,length:c.size_t)->f64{if values==nil||length!=1||values[0]<1||values[0]>3 do return INVALID_RESULT;sum:=f64(0);for pass:=i64(0);pass<values[0];pass+=1{sum+=f64(pass+1)*one_pass()};if !math.is_finite(sum) do return INVALID_RESULT;return sum}
