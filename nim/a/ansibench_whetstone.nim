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

import std/math
const InvalidResult = -1e300

proc pa(e: var array[5,float64], t: float64) =
  var j = 0
  while true:
    e[1] = (e[1]+e[2]+e[3]-e[4])*t
    e[2] = (e[1]+e[2]-e[3]+e[4])*t
    e[3] = (e[1]-e[2]+e[3]+e[4])*t
    e[4] = (-e[1]+e[2]+e[3]+e[4])/2.0
    inc j
    if j >= 6: break

proc p3(x,y: float64): float64 =
  var x1=x
  var y1=y
  x1=0.499975*(x1+y1)
  y1=0.499975*(x1+y1)
  (x1+y1)/2.0

proc add(sum,idx: var float64,value: float64) =
  sum += idx*value
  idx += 1.0

proc onePass(): float64 =
  let t=0.499975
  let t1=0.50025
  let t2=2.0
  var total=0.0
  var idx=1.0
  add(total,idx,1.0);add(total,idx,-1.0);add(total,idx,-1.0);add(total,idx,-1.0)
  var e=[0.0,1.0,-1.0,-1.0,-1.0]
  for _ in 0..<12:
    e[1]=(e[1]+e[2]+e[3]-e[4])*t
    e[2]=(e[1]+e[2]-e[3]+e[4])*t
    e[3]=(e[1]-e[2]+e[3]+e[4])*t
    e[4]=(-e[1]+e[2]+e[3]+e[4])*t
  add(total,idx,e[1]);add(total,idx,e[2]);add(total,idx,e[3]);add(total,idx,e[4])
  for _ in 0..<14: pa(e,t)
  add(total,idx,e[1]);add(total,idx,e[2]);add(total,idx,e[3]);add(total,idx,e[4])
  var j=1'i64
  for _ in 0..<345:
    j=if j==1:2 else:3
    j=if j>2:0 else:1
    j=if j<1:1 else:0
  add(total,idx,float64(j))
  j=1
  var k=2'i64
  var l=3'i64
  for _ in 0..<210:
    j=j*(k-j)*(l-k)
    k=l*k-(l-j)*k
    l=(l-k)*(k+j)
    e[int(l-1)]=float64(j+k+l)
    e[int(k-1)]=float64(j*k*l)
  add(total,idx,float64(j));add(total,idx,float64(k));add(total,idx,float64(l))
  add(total,idx,e[1]);add(total,idx,e[2]);add(total,idx,e[3]);add(total,idx,e[4])
  var x=0.5
  var y=0.5
  for _ in 0..<32:
    x=t*arctan(t2*sin(x)*cos(x)/(cos(x+y)+cos(x-y)-1.0))
    y=t*arctan(t2*sin(y)*cos(y)/(cos(x+y)+cos(x-y)-1.0))
  add(total,idx,x);add(total,idx,y)
  x=1.0;y=1.0
  var z=1.0
  for _ in 0..<899: z=p3(x,y)
  add(total,idx,x);add(total,idx,y);add(total,idx,z)
  j=1;k=2;l=3
  e[1]=1.0;e[2]=2.0;e[3]=3.0
  for _ in 0..<616:
    e[int(j)]=e[int(k)]
    e[int(k)]=e[int(l)]
    e[int(l)]=e[int(j)]
  add(total,idx,float64(j));add(total,idx,float64(k));add(total,idx,float64(l))
  add(total,idx,e[1]);add(total,idx,e[2]);add(total,idx,e[3]);add(total,idx,e[4])
  j=2;k=3
  add(total,idx,float64(j));add(total,idx,float64(k))
  x=0.75
  for _ in 0..<93: x=sqrt(exp(ln(x)/t1))
  add(total,idx,x)
  total

proc ansibench_whetstone*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl,exportc:"ansibench_whetstone".} =
  if values==nil or length!=1 or values[0]<1 or values[0]>3: return InvalidResult
  var total=0.0
  for pass in 0..<int(values[0]): total += float64(pass+1)*onePass()
  if classify(total) in {fcNan,fcInf,fcNegInf}: return InvalidResult
  total
