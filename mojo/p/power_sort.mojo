from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ps_less(a:Int64,b:Int64,rev:Bool)->Bool:return a>b if rev else a<b
fn ps_find(inout v:InlineArray[Int64,64],start:Int,end:Int,rev:Bool)->Int:
    if start>=end-1:return start+1
    var e=start+1
    if ps_less(v[e],v[start],rev):
        while e<end and ps_less(v[e],v[e-1],rev):e+=1
        var l=start;var r=e-1
        while l<r:let t=v[l];v[l]=v[r];v[r]=t;l+=1;r-=1
    else:
        while e<end and not ps_less(v[e],v[e-1],rev):e+=1
    return e
fn ps_power(total:Int,b1:Int,n1:Int,b2:Int,n2:Int)->Int:
    let a=2*b1+n1;let b=2*b2+n2;let den=2*total;var p=0
    while ((a*(1<<p))//den)==((b*(1<<p))//den):p+=1
    return p
fn ps_merge(inout v:InlineArray[Int64,64],start:Int,mid:Int,end:Int,rev:Bool):
    var left=InlineArray[Int64,64](fill=0);var right=InlineArray[Int64,64](fill=0)
    let nl=mid-start;let nr=end-mid
    for i in range(nl):left[i]=v[start+i]
    for i in range(nr):right[i]=v[mid+i]
    var i=0;var j=0;var o=start
    while i<nl and j<nr:
        let take=left[i]>=right[j] if rev else left[i]<=right[j]
        if take:v[o]=left[i];i+=1
        else:v[o]=right[j];j+=1
        o+=1
    while i<nl:v[o]=left[i];i+=1;o+=1
    while j<nr:v[o]=right[j];j+=1;o+=1

@export("power_sort")
fn power_sort(x:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if x==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return -1
    let rv=x[0];let raw=x[1]
    if (rv!=0 and rv!=1) or raw<0 or raw>64 or n!=c_size_t(2+raw):return -1
    let count=Int(raw);var vals=InlineArray[Int64,64](fill=0)
    for i in range(count):if x[i+2]< -1000000 or x[i+2]>1000000:return -1
    else:vals[i]=x[i+2]
    if count==0:return 0
    let needed=count*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    let rev=rv==1;var starts=InlineArray[Int,64](fill=0);var lens=InlineArray[Int,64](fill=0);var powers=InlineArray[Int,64](fill=0);var sp=0;var start=0
    while start<count:
        let end=ps_find(vals,start,count,rev);var runlen=end-start
        var power=0
        if sp>0:power=ps_power(count,starts[sp-1],lens[sp-1],start,runlen)
        while sp>0 and powers[sp-1]>=power:
            sp-=1;let prev=starts[sp];ps_merge(vals,prev,prev+lens[sp],end,rev);start=prev;runlen=end-start
            power=0
            if sp>0:power=ps_power(count,starts[sp-1],lens[sp-1],start,runlen)
        starts[sp]=start;lens[sp]=runlen;powers[sp]=power;sp+=1;start=end
    while sp>1:
        sp-=1;let rs=starts[sp];let re=rs+lens[sp];sp-=1;let ls=starts[sp];let mid=ls+lens[sp]
        ps_merge(vals,ls,mid,re,rev);let merged=re-ls;var power=0
        if sp>0:power=ps_power(count,starts[sp-1],lens[sp-1],ls,merged)
        starts[sp]=ls;lens[sp]=merged;powers[sp]=power;sp+=1
    for i in range(count):
        let bits=UInt64(vals[i])
        for b in range(8):out[i*8+b]=UInt8((bits>>(8*b))&255)
    return Int64(needed)
