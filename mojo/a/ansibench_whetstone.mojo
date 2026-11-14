# C Converted Whetstone Double Precision Benchmark
# Version 1.2  22 March 1998
#
# (c) Copyright 1998 Painter Engineering, Inc.
# All Rights Reserved.
#
# Permission is granted to use, duplicate, and
# publish this text and program as long as it
# includes this entire comment block and limited
# rights reference.
#
# Converted by Rich Painter, Painter Engineering, Inc. based on the
# www.netlib.org benchmark/whetstoned version obtained 16 March 1998.
#
# A novel approach was used here to keep the look and feel of the
# FORTRAN version.  Altering the FORTRAN-based array indices,
# starting at element 1, to start at element 0 for C, would require
# numerous changes, including decrementing the variable indices by 1.
# Instead, the array E1[] was declared 1 element larger in C.  This
# allows the FORTRAN index range to function without any literal or
# variable indices changes.  The array element E1[0] is simply never
# used and does not alter the benchmark results.
#
# The major FORTRAN comment blocks were retained to minimize
# differences between versions.  Modules N5 and N12, like in the
# FORTRAN version, have been eliminated here.
#
# An optional command-line argument has been provided [-c] to
# offer continuous repetition of the entire benchmark.
# An optional argument for setting an alternate LOOP count is also
# provided.  Define PRINTOUT to cause the POUT() function to print
# outputs at various stages.  Final timing measurements should be
# made with the PRINTOUT undefined.
#
# Questions and comments may be directed to the author at
# r.painter@ieee.org

from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import atan, cos, exp, log, sin, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

fn whet_include(value: Float64, inout checksum: Float64, inout index: Int):
    checksum += Float64(index)*value
    index += 1

fn whet_pa(mut e: InlineArray[Float64, 5], t: Float64):
    for _ in range(6):
        e[1]=(e[1]+e[2]+e[3]-e[4])*t
        e[2]=(e[1]+e[2]-e[3]+e[4])*t
        e[3]=(e[1]-e[2]+e[3]+e[4])*t
        e[4]=(-e[1]+e[2]+e[3]+e[4])/2.0

fn whet_p3(x: Float64, y: Float64, t: Float64) -> Float64:
    let xx = t*(x+y)
    let yy = t*(xx+y)
    return (xx+yy)/2.0

fn whet_pass() -> Float64:
    let t = Float64(0.499975)
    var checksum = Float64(0.0)
    var index = 1
    whet_include(1.0, checksum, index)
    for _ in range(3): whet_include(-1.0, checksum, index)
    var e = InlineArray[Float64, 5](fill=-1.0)
    e[0] = 0.0; e[1] = 1.0
    for _ in range(12):
        e[1]=(e[1]+e[2]+e[3]-e[4])*t
        e[2]=(e[1]+e[2]-e[3]+e[4])*t
        e[3]=(e[1]-e[2]+e[3]+e[4])*t
        e[4]=(-e[1]+e[2]+e[3]+e[4])*t
    for i in range(1,5): whet_include(e[i], checksum, index)
    for _ in range(14):
        whet_pa(e, t)
    for i in range(1,5): whet_include(e[i], checksum, index)
    var j = 1
    for _ in range(345):
        j = 2 if j == 1 else 3
        j = 0 if j > 2 else 1
        j = 1 if j < 1 else 0
    whet_include(Float64(j), checksum, index)
    j = 1; var k = 2; var l = 3
    for _ in range(210):
        j = j*(k-j)*(l-k)
        k = l*k-(l-j)*k
        l = (l-k)*(k+j)
        e[l-1] = Float64(j+k+l)
        e[k-1] = Float64(j*k*l)
    whet_include(Float64(j), checksum, index)
    whet_include(Float64(k), checksum, index)
    whet_include(Float64(l), checksum, index)
    for i in range(1,5): whet_include(e[i], checksum, index)
    var x = Float64(0.5); var y = Float64(0.5)
    for _ in range(32):
        x=t*atan(2.0*sin(x)*cos(x)/(cos(x+y)+cos(x-y)-1.0))
        y=t*atan(2.0*sin(y)*cos(y)/(cos(x+y)+cos(x-y)-1.0))
    whet_include(x, checksum, index); whet_include(y, checksum, index)
    x=1.0; y=1.0; var z = Float64(1.0)
    for _ in range(899):
        z = whet_p3(x, y, t)
    whet_include(x, checksum, index); whet_include(y, checksum, index); whet_include(z, checksum, index)
    j=1; k=2; l=3; e[1]=1.0; e[2]=2.0; e[3]=3.0
    for _ in range(616):
        e[j]=e[k]; e[k]=e[l]; e[l]=e[j]
    whet_include(Float64(j), checksum, index); whet_include(Float64(k), checksum, index)
    whet_include(Float64(l), checksum, index)
    for i in range(1,5): whet_include(e[i], checksum, index)
    whet_include(2.0, checksum, index); whet_include(3.0, checksum, index)
    x=0.75
    for _ in range(93): x=sqrt(exp(log(x)/0.50025))
    whet_include(x, checksum, index)
    return checksum

@export("ansibench_whetstone")
fn ansibench_whetstone(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1.0e300
    if values[0] < 1 or values[0] > 3: return -1.0e300
    var total = Float64(0.0)
    for pass_index in range(Int(values[0])):
        total += Float64(pass_index+1)*whet_pass()
    return total
