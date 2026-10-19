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

use std::ffi::c_double;
const INVALID_RESULT:f64=-1e300;
fn pa(e:&mut[f64;5],t:f64){let mut j=0;loop{e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])/2.0;j+=1;if j>=6{break;}}}
fn p3(x:f64,y:f64)->f64{let mut x1=x;let mut y1=y;x1=0.499975*(x1+y1);y1=0.499975*(x1+y1);(x1+y1)/2.0}
fn one_pass()->f64{let(t,t1,t2)=(0.499975,0.50025,2.0);let(mut sum,mut idx)=(0.0,1.0);macro_rules! include{($v:expr)=>{{sum+=idx*($v);idx+=1.0;}}}
 let(x1,x2,x3,x4)=(1.0,-1.0,-1.0,-1.0);include!(x1);include!(x2);include!(x3);include!(x4);
 let mut e=[0.0,1.0,-1.0,-1.0,-1.0];for _ in 0..12{e[1]=(e[1]+e[2]+e[3]-e[4])*t;e[2]=(e[1]+e[2]-e[3]+e[4])*t;e[3]=(e[1]-e[2]+e[3]+e[4])*t;e[4]=(-e[1]+e[2]+e[3]+e[4])*t;}include!(e[1]);include!(e[2]);include!(e[3]);include!(e[4]);
 for _ in 0..14{pa(&mut e,t);}include!(e[1]);include!(e[2]);include!(e[3]);include!(e[4]);
 let mut j=1i64;for _ in 0..345{j=if j==1{2}else{3};j=if j>2{0}else{1};j=if j<1{1}else{0};}include!(j as f64);
 j=1;let(mut k,mut l)=(2i64,3i64);for _ in 0..210{j=j*(k-j)*(l-k);k=l*k-(l-j)*k;l=(l-k)*(k+j);e[(l-1)as usize]=(j+k+l)as f64;e[(k-1)as usize]=(j*k*l)as f64;}include!(j as f64);include!(k as f64);include!(l as f64);include!(e[1]);include!(e[2]);include!(e[3]);include!(e[4]);
 let(mut x,mut y)=(0.5,0.5);for _ in 0..32{x=t*(t2*x.sin()*x.cos()/( (x+y).cos()+(x-y).cos()-1.0)).atan();y=t*(t2*y.sin()*y.cos()/((x+y).cos()+(x-y).cos()-1.0)).atan();}include!(x);include!(y);
 x=1.0;y=1.0;let mut z=1.0;for _ in 0..899{z=p3(x,y);}include!(x);include!(y);include!(z);
 j=1;k=2;l=3;e[1]=1.0;e[2]=2.0;e[3]=3.0;for _ in 0..616{e[j as usize]=e[k as usize];e[k as usize]=e[l as usize];e[l as usize]=e[j as usize];}include!(j as f64);include!(k as f64);include!(l as f64);include!(e[1]);include!(e[2]);include!(e[3]);include!(e[4]);
 j=2;k=3;include!(j as f64);include!(k as f64);x=0.75;for _ in 0..93{x=(x.ln()/t1).exp().sqrt();}include!(x);sum}
#[no_mangle]
pub unsafe extern "C" fn ansibench_whetstone(values:*const i64,length:usize)->c_double{if values.is_null()||length!=1{return INVALID_RESULT;}let count=unsafe{*values};if !(1..=3).contains(&count){return INVALID_RESULT;}let mut total=0.0;for pass in 0..count{total+=(pass+1)as f64*one_pass();}if total.is_finite(){total}else{INVALID_RESULT}}
