from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 24
const MAX_M = 24
const MAX_Q = 128
const INPUT_MAX = 483
const BIT_STRIDE = MAX_M + 1

fn angle_less(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Bool:
    var ah = 2
    var bh = 2
    if ay < 0: ah = 0
    elif ay == 0 and ax >= 0: ah = 1
    if by < 0: bh = 0
    elif by == 0 and bx >= 0: bh = 1
    if ah != bh: return ah < bh
    return ax * by - ay * bx > 0

fn direction_less(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Bool:
    if angle_less(ax,ay,bx,by): return True
    if angle_less(bx,by,ax,ay): return False
    let ar=ax*ax+ay*ay
    let br=bx*bx+by*by
    if ar != br: return ar < br
    if ax != bx: return ax < bx
    return ay < by

fn lower_ray(inout xs: InlineArray[Int64, MAX_N * MAX_M], inout ys: InlineArray[Int64, MAX_N * MAX_M], base: Int, count: Int, rx: Int64, ry: Int64) -> Int:
    var low=0
    var high=count
    while low < high:
        let mid=low+(high-low)/2
        if angle_less(xs[base+mid],ys[base+mid],rx,ry): low=mid+1
        else: high=mid
    return low

fn upper_ray(inout xs: InlineArray[Int64, MAX_N * MAX_M], inout ys: InlineArray[Int64, MAX_N * MAX_M], base: Int, count: Int, rx: Int64, ry: Int64) -> Int:
    var low=0
    var high=count
    while low < high:
        let mid=low+(high-low)/2
        if not angle_less(rx,ry,xs[base+mid],ys[base+mid]): low=mid+1
        else: high=mid
    return low

fn fenwick_prefix(inout bit: InlineArray[Int32, MAX_N * BIT_STRIDE], base: Int, end_value: Int) -> Int32:
    var end=end_value
    var total:Int32=0
    while end > 0:
        total+=bit[base+end]
        end &= end-1
    return total

fn arc_count(inout xs: InlineArray[Int64, MAX_N * MAX_M], inout ys: InlineArray[Int64, MAX_N * MAX_M],
    inout bit: InlineArray[Int32, MAX_N * BIT_STRIDE], base: Int, count: Int,
    sx: Int64, sy: Int64, ex: Int64, ey: Int64) -> Int32:
    let left=lower_ray(xs,ys,base,count,sx,sy)
    let right=upper_ray(xs,ys,base,count,ex,ey)
    if not angle_less(ex,ey,sx,sy): return fenwick_prefix(bit,base/(MAX_M)*BIT_STRIDE,right)-fenwick_prefix(bit,base/(MAX_M)*BIT_STRIDE,left)
    let bit_base=base/(MAX_M)*BIT_STRIDE
    return fenwick_prefix(bit,bit_base,count)-fenwick_prefix(bit,bit_base,left)+fenwick_prefix(bit,bit_base,right)

fn halfplane_count(u: Int, v: Int, inout ax: InlineArray[Int64, MAX_N], inout ay: InlineArray[Int64, MAX_N],
    inout xs: InlineArray[Int64, MAX_N * MAX_M], inout ys: InlineArray[Int64, MAX_N * MAX_M],
    inout counts: InlineArray[Int32, MAX_N], inout zeros: InlineArray[Int32, MAX_N],
    inout bit: InlineArray[Int32, MAX_N * BIT_STRIDE]) -> Int32:
    let dx=ax[v]-ax[u]
    let dy=ay[v]-ay[u]
    let base=u*MAX_M
    return zeros[u]+arc_count(xs,ys,bit,base,Int(counts[u]),-dx,-dy,dx,dy)

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=bitcast[UInt64](value)
    for byte in range(8): output[offset+byte]=UInt8((bits>>UInt(8*byte))&255)

@export("count_points_in_triangle")
fn count_points_in_triangle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>INPUT_MAX: return -1
    let nr=input[0]
    let mr=input[1]
    let qr=input[2]
    if nr<1 or nr>MAX_N or mr<1 or mr>MAX_M or qr<1 or qr>MAX_Q: return -1
    let n=Int(nr)
    let m=Int(mr)
    let q=Int(qr)
    if length != c_size_t(3+2*n+2*m+3*q): return -1
    var ax=InlineArray[Int64,MAX_N]()
    var ay=InlineArray[Int64,MAX_N]()
    var bx=InlineArray[Int64,MAX_M]()
    var by=InlineArray[Int64,MAX_M]()
    var queries=InlineArray[Int64,3*MAX_Q]()
    var cursor=3
    for i in range(n):
        ax[i]=input[cursor]
        ay[i]=input[cursor+1]
        cursor+=2
        if ax[i] < -1000000000 or ax[i] > 1000000000 or ay[i] < -1000000000 or ay[i] > 1000000000: return -1
    for i in range(m):
        bx[i]=input[cursor]
        by[i]=input[cursor+1]
        cursor+=2
        if bx[i] < -1000000000 or bx[i] > 1000000000 or by[i] < -1000000000 or by[i] > 1000000000: return -1
    for i in range(q):
        let ia=input[cursor]
        let ib=input[cursor+1]
        let ic=input[cursor+2]
        cursor+=3
        if ia<0 or ia>=nr or ib<0 or ib>=nr or ic<0 or ic>=nr: return -1
        queries[3*i]=ia
        queries[3*i+1]=ib
        queries[3*i+2]=ic
    let required=8*q
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required): return -2

    var xs=InlineArray[Int64,MAX_N*MAX_M]()
    var ys=InlineArray[Int64,MAX_N*MAX_M]()
    var counts=InlineArray[Int32,MAX_N]()
    var zeros=InlineArray[Int32,MAX_N]()
    var bit=InlineArray[Int32,MAX_N*BIT_STRIDE]()
    for u in range(n):
        let base=u*MAX_M
        for j in range(m):
            let dx=bx[j]-ax[u]
            let dy=by[j]-ay[u]
            if dx==0 and dy==0: zeros[u]+=1
            else:
                let at=Int(counts[u])
                xs[base+at]=dx
                ys[base+at]=dy
                counts[u]+=1
        for i in range(1,Int(counts[u])):
            let item_x=xs[base+i]
            let item_y=ys[base+i]
            var j=i
            while j>0 and direction_less(item_x,item_y,xs[base+j-1],ys[base+j-1]):
                xs[base+j]=xs[base+j-1]
                ys[base+j]=ys[base+j-1]
                j-=1
            xs[base+j]=item_x
            ys[base+j]=item_y
        let bit_base=u*BIT_STRIDE
        for i in range(Int(counts[u])):
            var at=i+1
            while at<=Int(counts[u]):
                bit[bit_base+at]+=1
                at+=at&(~at+1)

    var answers=InlineArray[Int64,MAX_Q]()
    for qi in range(q):
        let ia=Int(queries[3*qi])
        var ib=Int(queries[3*qi+1])
        var ic=Int(queries[3*qi+2])
        let orient=(ax[ib]-ax[ia])*(ay[ic]-ay[ia])-(ay[ib]-ay[ia])*(ax[ic]-ax[ia])
        if orient==0: answers[qi]=0; continue
        if orient<0:
            let temp=ib
            ib=ic
            ic=temp
        let outside=halfplane_count(ia,ib,ax,ay,xs,ys,counts,zeros,bit)+halfplane_count(ib,ic,ax,ay,xs,ys,counts,zeros,bit)+halfplane_count(ic,ia,ax,ay,xs,ys,counts,zeros,bit)
        let b_base=ib*MAX_M
        let c_base=ic*MAX_M
        let a_base=ia*MAX_M
        let pairs=zeros[ib]+arc_count(xs,ys,bit,b_base,Int(counts[ib]),ax[ib]-ax[ic],ay[ib]-ay[ic],ax[ib]-ax[ia],ay[ib]-ay[ia])
          +zeros[ic]+arc_count(xs,ys,bit,c_base,Int(counts[ic]),ax[ic]-ax[ia],ay[ic]-ay[ia],ax[ic]-ax[ib],ay[ic]-ay[ib])
          +zeros[ia]+arc_count(xs,ys,bit,a_base,Int(counts[ia]),ax[ia]-ax[ib],ay[ia]-ay[ib],ax[ia]-ax[ic],ay[ia]-ay[ic])
        answers[qi]=Int64(m)-Int64(outside)+Int64(pairs)
    for i in range(q):
        store_le(output,8*i,answers[i])
    return Int64(required)
