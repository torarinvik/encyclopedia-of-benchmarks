from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sf_build(freq:UnsafePointer[Int32,ImmutAnyOrigin],sym:UnsafePointer[Int32,MutAnyOrigin],lo:Int,hi:Int,bits:UnsafePointer[UInt16,MutAnyOrigin],lens:UnsafePointer[Int32,MutAnyOrigin],prefix:UInt16,depth:Int):
    if lo==hi:let s=Int(sym[lo]);bits[s]=prefix;lens[s]=depth;return
    var total=0;for i in range(lo,hi+1):total+=freq[Int(sym[i])]
    var left=0;var best=2147483647;var split=lo
    for i in range(lo,hi):
        left+=freq[Int(sym[i])];let diff=abs(2*left-total)
        if diff<best:best=diff;split=i
    sf_build(freq,sym,lo,split,bits,lens,prefix<<1,depth+1)
    sf_build(freq,sym,split+1,hi,bits,lens,(prefix<<1)|1,depth+1)
@export("shannon_fano_generate_codes")
fn shannon_fano_generate_codes(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if (a==UnsafePointer[Int64,ImmutAnyOrigin]() and n!=0) or (a!=UnsafePointer[Int64,ImmutAnyOrigin]() and (n<1 or n>65)):return -1
    var textn=0
    if n>0:
        let count=a[0];if count<0 or count>64 or n!=c_size_t(count+1):return -1;textn=Int(count)
    var freq=InlineArray[Int32,128]();var sym=InlineArray[Int32,128]();var ns=0
    for i in range(textn):let c=if n==0 then 0 else a[i+1];if c<0 or c>127:return -1;if freq[Int(c)]==0:sym[ns]=Int32(c);ns+=1;freq[Int(c)]+=1
    if ns>10:return -1
    for i in range(ns):for j in range(i+1,ns):if freq[sym[i]]==freq[sym[j]]:return -1
    for i in range(1,ns):let x=sym[i];var j=i;while j>0 and freq[sym[j-1]]<freq[x]:sym[j]=sym[j-1];j-=1;sym[j]=x
    var bits=InlineArray[UInt16,128]();var lens=InlineArray[Int32,128]()
    if ns==1:lens[sym[0]]=1
    elif ns>1:sf_build(freq.unsafe_ptr(),sym.unsafe_ptr(),0,ns-1,bits.unsafe_ptr(),lens.unsafe_ptr(),0,0)
    var out=InlineArray[UInt8,111]();var p=0;out[p]=UInt8(ns);p+=1
    for c in range(128):
        let l=Int(lens[c]);if l>0:out[p]=UInt8(c);out[p+1]=UInt8(l);p+=2;for j in range(l):out[p]=UInt8(48+((bits[c]>>UInt(l-1-j))&1));p+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(p):return -2
    for i in range(p):o[i]=out[i]
    return Int64(p)
