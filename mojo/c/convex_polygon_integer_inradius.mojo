# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@fieldwise_init
struct IrLine(Copyable):
    var a: Int64
    var b: Int64
    var c: Int64
    var norm: Int64

@fieldwise_init
struct IrPoint(Copyable):
    var x: Int64
    var y: Int64
    var den: Int64

fn ir_abs(x: Int64) -> Int64:
    if x < 0: -x else: x

fn ir_gcd(x: Int64, y: Int64) -> Int64:
    var a=ir_abs(x)
    var b=ir_abs(y)
    while b != 0:
        let rem=a % b
        a=b
        b=rem
    a

fn ir_half(l: IrLine) -> Int:
    if l.b > 0 or (l.b == 0 and l.a >= 0): 0 else: 1

fn ir_before(a: IrLine, b: IrLine) -> Bool:
    let ha=ir_half(a)
    let hb=ir_half(b)
    if ha != hb: return ha < hb
    let cross=a.a*b.b-a.b*b.a
    if cross != 0: return cross > 0
    a.c < b.c

fn ir_intersect(a: IrLine, b: IrLine) -> (Bool, IrPoint):
    var den=a.a*b.b-b.a*a.b
    if den == 0: return (False, IrPoint(0,0,1))
    var x=a.c*b.b-a.b*b.c
    var y=a.a*b.c-a.c*b.a
    if den < 0:
        den = -den
        x = -x
        y = -y
    (True, IrPoint(x,y,den))

fn ir_outside(l: IrLine, p: IrPoint) -> Bool:
    l.a*p.x+l.b*p.y > l.c*p.den

fn ir_feasible(lines: InlineArray[IrLine, 16], count: Int, radius: Int64) -> Bool:
    var queue=InlineArray[IrLine, 16](fill=IrLine(0,0,0,0))
    var head=0
    var tail=0
    for i in range(count):
        var h=lines[i]
        h.c=h.c*32768-(radius*32768-1)*h.norm
        if tail > head and queue[tail-1].a == h.a and queue[tail-1].b == h.b:
            if h.c >= queue[tail-1].c: continue
            tail -= 1
        while tail-head > 1:
            let (valid,p)=ir_intersect(queue[tail-2],queue[tail-1])
            if not valid or not ir_outside(h,p): break
            tail -= 1
        while tail-head > 1:
            let (valid,p)=ir_intersect(queue[head],queue[head+1])
            if not valid or not ir_outside(h,p): break
            head += 1
        if tail > head and queue[tail-1].a*h.b-queue[tail-1].b*h.a == 0: return False
        queue[tail]=h
        tail += 1
    while tail-head > 2:
        let (valid,p)=ir_intersect(queue[tail-2],queue[tail-1])
        if not valid or not ir_outside(queue[head],p): break
        tail -= 1
    while tail-head > 2:
        let (valid,p)=ir_intersect(queue[head],queue[head+1])
        if not valid or not ir_outside(queue[tail-1],p): break
        head += 1
    if tail-head < 3: return False
    for i in range(head,tail):
        let j=if i+1 == tail: head else: i+1
        let (valid,_)=ir_intersect(queue[i],queue[j])
        if not valid: return False
    True

@export("convex_polygon_integer_inradius")
fn convex_polygon_integer_inradius(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 38: return -1
    if input[0] < 0 or input[0] > 12: return -1
    let n=Int(input[0])
    if length != c_size_t(1+3*n): return -1
    var lines=InlineArray[IrLine, 16](fill=IrLine(0,0,0,0))
    for i in range(n):
        let a=input[1+3*i]
        let b=input[2+3*i]
        let c=input[3+3*i]
        if a < -15 or a > 15 or b < -15 or b > 15 or c < -128 or c > 128: return -1
        let squared=a*a+b*b
        var norm=Int64(0)
        while norm*norm < squared: norm += 1
        if norm == 0 or norm*norm != squared or ir_gcd(a,b) != 1: return -1
        lines[i]=IrLine(a,b,c,norm)
    lines[n]=IrLine(1,0,256,1); lines[n+1]=IrLine(0,1,256,1)
    lines[n+2]=IrLine(-1,0,256,1); lines[n+3]=IrLine(0,-1,256,1)
    let count=n+4
    var scratch=InlineArray[IrLine, 16](fill=IrLine(0,0,0,0))
    var width=1
    while width < count:
        var start=0
        while start < count:
            let middle=min(start+width,count)
            let end=min(start+2*width,count)
            var i=start
            var j=middle
            var k=start
            while i < middle and j < end:
                if ir_before(lines[j],lines[i]):
                    scratch[k]=lines[j]
                    j += 1
                else:
                    scratch[k]=lines[i]
                    i += 1
                k += 1
            while i < middle:
                scratch[k]=lines[i]
                i += 1
                k += 1
            while j < end:
                scratch[k]=lines[j]
                j += 1
                k += 1
            start += 2*width
        for i in range(count): lines[i]=scratch[i]
        width *= 2
    if not ir_feasible(lines,count,0): return -2
    var low=Int64(0)
    var high=Int64(257)
    while high-low > 1:
        let middle=(low+high)/2
        if ir_feasible(lines,count,middle): low=middle
        else: high=middle
    low
