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

const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;

fn pa(e: *[5]f64, t: f64) void {
    var j: usize = 0;
    while (true) {
        e[1] = (e[1] + e[2] + e[3] - e[4]) * t;
        e[2] = (e[1] + e[2] - e[3] + e[4]) * t;
        e[3] = (e[1] - e[2] + e[3] + e[4]) * t;
        e[4] = (-e[1] + e[2] + e[3] + e[4]) / 2.0;
        j += 1;
        if (j >= 6) break;
    }
}

fn p3(x: f64, y: f64) f64 {
    var x1 = x;
    var y1 = y;
    x1 = 0.499975 * (x1 + y1);
    y1 = 0.499975 * (x1 + y1);
    return (x1 + y1) / 2.0;
}

fn add(sum: *f64, idx: *f64, value: f64) void {
    sum.* += idx.* * value;
    idx.* += 1.0;
}

fn onePass() f64 {
    const t = 0.499975;
    const t1 = 0.50025;
    const t2 = 2.0;
    var sum: f64 = 0.0;
    var idx: f64 = 1.0;
    add(&sum,&idx,1.0);add(&sum,&idx,-1.0);add(&sum,&idx,-1.0);add(&sum,&idx,-1.0);
    var e = [5]f64{0.0,1.0,-1.0,-1.0,-1.0};
    for (0..12) |_| {
        e[1]=(e[1]+e[2]+e[3]-e[4])*t;
        e[2]=(e[1]+e[2]-e[3]+e[4])*t;
        e[3]=(e[1]-e[2]+e[3]+e[4])*t;
        e[4]=(-e[1]+e[2]+e[3]+e[4])*t;
    }
    for (1..5) |i| add(&sum,&idx,e[i]);
    for (0..14) |_| pa(&e,t);
    for (1..5) |i| add(&sum,&idx,e[i]);
    var j: i64 = 1;
    for (0..345) |_| {
        j=if(j==1) 2 else 3;
        j=if(j>2) 0 else 1;
        j=if(j<1) 1 else 0;
    }
    add(&sum,&idx,@floatFromInt(j));
    j=1;
    var k: i64=2;
    var l: i64=3;
    for (0..210) |_| {
        j=j*(k-j)*(l-k);
        k=l*k-(l-j)*k;
        l=(l-k)*(k+j);
        e[@intCast(l-1)]=@floatFromInt(j+k+l);
        e[@intCast(k-1)]=@floatFromInt(j*k*l);
    }
    add(&sum,&idx,@floatFromInt(j));add(&sum,&idx,@floatFromInt(k));add(&sum,&idx,@floatFromInt(l));
    for (1..5) |i| add(&sum,&idx,e[i]);
    var x: f64=0.5;
    var y: f64=0.5;
    for (0..32) |_| {
        x=t*@atan(t2*@sin(x)*@cos(x)/(@cos(x+y)+@cos(x-y)-1.0));
        y=t*@atan(t2*@sin(y)*@cos(y)/(@cos(x+y)+@cos(x-y)-1.0));
    }
    add(&sum,&idx,x);add(&sum,&idx,y);
    x=1.0;y=1.0;
    var z: f64=1.0;
    for (0..899) |_| z=p3(x,y);
    add(&sum,&idx,x);add(&sum,&idx,y);add(&sum,&idx,z);
    j=1;k=2;l=3;e[1]=1.0;e[2]=2.0;e[3]=3.0;
    for (0..616) |_| {
        e[@intCast(j)]=e[@intCast(k)];
        e[@intCast(k)]=e[@intCast(l)];
        e[@intCast(l)]=e[@intCast(j)];
    }
    add(&sum,&idx,@floatFromInt(j));add(&sum,&idx,@floatFromInt(k));add(&sum,&idx,@floatFromInt(l));
    for (1..5) |i| add(&sum,&idx,e[i]);
    j=2;k=3;add(&sum,&idx,@floatFromInt(j));add(&sum,&idx,@floatFromInt(k));
    x=0.75;
    for (0..93) |_| x=@sqrt(@exp(@log(x)/t1));
    add(&sum,&idx,x);
    return sum;
}

export fn ansibench_whetstone(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 1 or values[0] < 1 or values[0] > 3) return INVALID_RESULT;
    var total: f64 = 0.0;
    const passes: usize = @intCast(values[0]);
    for (0..passes) |pass| total += @as(f64,@floatFromInt(pass+1))*onePass();
    return if (std.math.isFinite(total)) total else INVALID_RESULT;
}
