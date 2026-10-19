from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sfc_build(freq:UnsafePointer[Int32,ImmutAnyOrigin],sym:UnsafePointer[Int32,ImmutAnyOrigin],lo:Int,hi:Int,bits:UnsafePointer[UInt16,MutAnyOrigin],lens:UnsafePointer[Int32,MutAnyOrigin],prefix:UInt16,depth:Int)->Bool:
    if lo==hi:let c=Int(sym[lo]);bits[c]=prefix;lens[c]=depth;return True
    var total=0;for i in range(lo,hi+1):total+=freq[Int(sym[i])]
    var running=0;var split=lo-1
    for i in range(lo,hi):
        let f=freq[Int(sym[i])]
        if 2*(running+f)<=total:running+=f;split=i
        else:break
    if split<lo or split>=hi:return False
    if not sfc_build(freq,sym,lo,split,bits,lens,prefix<<1,depth+1):return False
    return sfc_build(freq,sym,split+1,hi,bits,lens,(prefix<<1)|1,depth+1)
@export("shannon_fano_compressor")
fn shannon_fano_compressor(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if (a==UnsafePointer[Int64,ImmutAnyOrigin]() and n!=0) or (a!=UnsafePointer[Int64,ImmutAnyOrigin]() and (n<1 or n>17)):return -1
    var textn=0;if n>0:let count=a[0];if count<0 or count>16 or n!=c_size_t(count+1):return -1;textn=Int(count)
    var freq=InlineArray[Int32,128]();var sym=InlineArray[Int32,16]();var ns=0;var text=InlineArray[Int32,16]()
    for i in range(textn):let c=a[i+1];if c<0 or c>127:return -1;text[i]=Int32(c);if freq[Int(c)]==0:sym[ns]=Int32(c);ns+=1;freq[Int(c)]+=1
    var bits=InlineArray[UInt16,128]();var lens=InlineArray[Int32,128]()
    if ns==1:lens[sym[0]]=1;bits[sym[0]]=1
    elif ns>1:if not sfc_build(freq.unsafe_ptr(),sym.unsafe_ptr(),0,ns-1,bits.unsafe_ptr(),lens.unsafe_ptr(),0,0):return -1
    var out=InlineArray[UInt8,514]();var p=0;var compressed=0
    for i in range(textn):compressed+=lens[text[i]]
    out[p]=UInt8(compressed);p+=1
    for i in range(textn):
        let c=Int(text[i]);for j in range(Int(lens[c])):out[p]=UInt8(48+((bits[c]>>UInt(Int(lens[c])-j-1))&1));p+=1
    out[p]=UInt8(ns);p+=1
    for c in range(128):
        let l=Int(lens[c]);if l>0:out[p]=UInt8(c);out[p+1]=UInt8(l);p+=2;for j in range(l):out[p]=UInt8(48+((bits[c]>>UInt(l-j-1))&1));p+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(p):return -2
    for i in range(p):o[i]=out[i]
    return Int64(p)
