from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn swp_u32(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:UInt32):
    for b in range(4):o[p+b]=UInt8((v>>(8*b))&255)
fn swp_pair(x:Int64,y:Int64,g:Int64,m:Int64,mm:Int64)->Int32:
    if x==45 or y==45:return Int32(g)
    let xx=if x>=97 then x-32 else x;let yy=if y>=97 then y-32 else y
    return Int32(m if xx==yy else mm)
@export("smith_waterman_python")
fn smith_waterman_python(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>38:return -1
    let qn=a[0];let sn=a[1];let m=a[2];let mm=a[3];let gap=a[4]
    if qn<0 or qn>16 or sn<0 or sn>16 or m<1 or m>5 or mm< -5 or mm> -1 or gap< -5 or gap> -1 or n!=c_size_t(5+qn+sn):return -1
    for i in range(Int(qn+sn)):
        let c=a[i+5];if not ((c>=65 and c<=90) or (c>=97 and c<=122) or c==45):return -1
    var dp=InlineArray[Int32,289]();var best:Int32=0;var mr=0;var mc=0
    for r in range(1,Int(qn)+1):for c in range(1,Int(sn)+1):
        let d=dp[(r-1)*17+c-1]+swp_pair(a[4+r],a[4+Int(qn)+c],gap,m,mm)
        let u=dp[(r-1)*17+c]+Int32(gap);let l=dp[r*17+c-1]+Int32(gap)
        var v=d;if u>v:v=u;if l>v:v=l;if v<0:v=0
        dp[r*17+c]=v;if v>best:best=v;mr=r;mc=c
    var rq=InlineArray[UInt8,32]();var rs=InlineArray[UInt8,32]();var steps=0;var r=mr;var c=mc
    while r>0 and c>0:
        let current=dp[r*17+c]
        let diag=dp[(r-1)*17+c-1]+swp_pair(a[4+r],a[4+Int(qn)+c],1,-1,-2)
        if current==diag:rq[steps]=UInt8(if a[4+r]>=97 then a[4+r]-32 else a[4+r]);rs[steps]=UInt8(if a[4+Int(qn)+c]>=97 then a[4+Int(qn)+c]-32 else a[4+Int(qn)+c]);r-=1;c-=1
        elif current==dp[(r-1)*17+c]-2:rq[steps]=UInt8(if a[4+r]>=97 then a[4+r]-32 else a[4+r]);rs[steps]=45;r-=1
        else:rq[steps]=45;rs[steps]=UInt8(if a[4+Int(qn)+c]>=97 then a[4+Int(qn)+c]-32 else a[4+Int(qn)+c]);c-=1
        steps+=1
    let rows=Int(qn)+1;let cols=Int(sn)+1;let alen=0 if steps==0 else steps*2+1;let need=8+rows*cols*4+4+alen
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    swp_u32(o,0,UInt32(rows));swp_u32(o,4,UInt32(cols));var p=8
    for i in range(rows):for j in range(cols):swp_u32(o,p,bitcast[UInt32](dp[i*17+j]));p+=4
    swp_u32(o,p,UInt32(alen));p+=4
    if steps>0:
        for i in range(steps):o[p+i]=rq[steps-1-i]
        p+=steps;o[p]=10;p+=1
        for i in range(steps):o[p+i]=rs[steps-1-i]
    return need
