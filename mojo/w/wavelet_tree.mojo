from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn wt_build(v:InlineArray[Int32,64],count:Int,low:Int,high:Int,node:Int,inout pref:InlineArray[Int32,8320],inout left:InlineArray[Int32,128],inout right:InlineArray[Int32,128],inout lows:InlineArray[Int32,128],inout highs:InlineArray[Int32,128],inout nodes:Int):
    lows[node]=Int32(low);highs[node]=Int32(high)
    if low==high:return
    let mid=(low+high)/2;var lp=0
    for i in range(count):if Int(v[i])<=mid:lp+=1
    pref[node*65]=0;var seen=0
    for i in range(count):if Int(v[i])<=mid:seen+=1;pref[node*65+i+1]=Int32(seen);else:pref[node*65+i+1]=Int32(seen)
    var lv=InlineArray[Int32,64]();var rv=InlineArray[Int32,64]();var li=0;var ri=0
    for i in range(count):
        if Int(v[i])<=mid:lv[li]=v[i];li+=1
        else:rv[ri]=v[i];ri+=1
    if li>0:left[node]=Int32(nodes);nodes+=1;wt_build(lv,li,low,mid,Int(left[node]),pref,left,right,lows,highs,nodes)
    if ri>0:right[node]=Int32(nodes);nodes+=1;wt_build(rv,ri,mid+1,high,Int(right[node]),pref,left,right,lows,highs,nodes)
fn wt_rank(value:Int,b:Int,n:Int,inout pref:InlineArray[Int32,8320],left:InlineArray[Int32,128],right:InlineArray[Int32,128],lows:InlineArray[Int32,128],highs:InlineArray[Int32,128])->Int:
    if b<0:return 0
    var node=0;var l=0;var r=b+1
    while lows[node]!=highs[node]:
        let lc=Int(pref[node*65+l]);let rc=Int(pref[node*65+r])
        if value<=(Int(lows[node])+Int(highs[node]))/2:
            if left[node]<0:return 0
            node=Int(left[node]);l=lc;r=rc
        else:
            if right[node]<0:return 0
            node=Int(right[node]);l-=lc;r-=rc
    return r-l if Int(lows[node])==value else 0
fn wt_quantile(a:Int,b:Int,k:Int,inout pref:InlineArray[Int32,8320],left:InlineArray[Int32,128],right:InlineArray[Int32,128])->Int:
    var node=0;var l=a;var r=b+1;var rank=k
    while left[node]>=0 or right[node]>=0:
        let lc=Int(pref[node*65+l]);let rc=Int(pref[node*65+r]);let leftn=rc-lc
        if rank<leftn:node=Int(left[node]);l=lc;r=rc
        else:rank-=leftn;node=Int(right[node]);l-=lc;r-=rc
    return Int(lows[node])
fn wt_range_count(a:Int,b:Int,c:Int,d:Int,inout pref:InlineArray[Int32,8320],left:InlineArray[Int32,128],right:InlineArray[Int32,128],lows:InlineArray[Int32,128],highs:InlineArray[Int32,128])->Int:
    var stackn=InlineArray[Int32,128]();var stackl=InlineArray[Int32,128]();var stackr=InlineArray[Int32,128]();var top=1;stackn[0]=0;stackl[0]=Int32(a);stackr[0]=Int32(b+1);var total=0
    while top>0:
        top-=1;let node=Int(stackn[top]);let l=Int(stackl[top]);let r=Int(stackr[top])
        if r<=l or Int(highs[node])<c or Int(lows[node])>d:continue
        if c<=Int(lows[node]) and Int(highs[node])<=d:total+=r-l;continue
        let lc=Int(pref[node*65+l]);let rc=Int(pref[node*65+r])
        if left[node]>=0:stackn[top]=left[node];stackl[top]=Int32(lc);stackr[top]=Int32(rc);top+=1
        if right[node]>=0:stackn[top]=right[node];stackl[top]=Int32(l-lc);stackr[top]=Int32(r-rc);top+=1
    return total
@export("wavelet_tree_benchmark")
fn wavelet_tree_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>706:return -1
    let count=a[0]
    if count<1 or count>64 or n<c_size_t(count+2):return -1
    var values=InlineArray[Int32,64]()
    for i in range(Int(count)):
        if a[i+1]< -1000 or a[i+1]>1000:return -1
        values[i]=Int32(a[i+1])
    let q=a[Int(count)+1]
    if q<0 or q>128 or n!=c_size_t(count+2+5*q):return -1
    var pref=InlineArray[Int32,8320]();var left=InlineArray[Int32,128]();var right=InlineArray[Int32,128]();var lows=InlineArray[Int32,128]();var highs=InlineArray[Int32,128]();var nodes=1
    for i in range(128):left[i]= -1;right[i]= -1
    wt_build(values,Int(count),-1000,1000,0,pref,left,right,lows,highs,nodes)
    var result:Int64=0;let offset=Int(count)+2
    for qi in range(Int(q)):
        let p=offset+qi*5;let op=a[p];let x=a[p+1];let y=a[p+2];let c=a[p+3];let d=a[p+4];var answer=0
        if op==0:
            if x< -1000 or x>1000 or y< -1 or y>=count:return -1
            answer=wt_rank(Int(x),Int(y),Int(count),pref,left,right,lows,highs)
        elif op==1:
            if x<0 or y<x or y>=count or c<0 or c>y-x:return -1
            answer=wt_quantile(Int(x),Int(y),Int(c),pref,left,right)
        elif op==2:
            if x<0 or y<x or y>=count or c>d or c< -1000 or c>1000 or d< -1000 or d>1000:return -1
            answer=wt_range_count(Int(x),Int(y),Int(c),Int(d),pref,left,right,lows,highs)
        else:return -1
        result+=(Int64(qi)+1)*(Int64(answer)+1000001)
    return result
