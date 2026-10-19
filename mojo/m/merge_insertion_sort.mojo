from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn mis_binary(mut a:InlineArray[Int64,256],mut n:Int,x:Int64):
    var l=0;var h=n
    while l<h:
        let m=l+(h-l)//2
        if a[m]<x:l=m+1
        else:h=m
    var i=n
    while i>l:a[i]=a[i-1];i-=1
    a[l]=x;n+=1
@export("merge_insertion_sort")
fn merge_insertion_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n>256 or v==UnsafePointer[Int64,MutAnyOrigin]():return
    var lows=InlineArray[Int64,128](fill=0);var highs=InlineArray[Int64,128](fill=0);let pairs=Int(n)//2
    for p in range(pairs):
        let x=v[p*2];let y=v[p*2+1]
        if x<=y:lows[p]=x;highs[p]=y
        else:lows[p]=y;highs[p]=x
    var width=1
    while width<pairs:
        for s in range(0,pairs,width*2):
            let m=min(s+width,pairs);let e=min(m+width,pairs);var i=s;var j=m;var lo=InlineArray[Int64,128](fill=0);var hi=InlineArray[Int64,128](fill=0);var k=s
            while i<m and j<e:
                let q=if lows[i]<=lows[j]:i else:j
                lo[k]=lows[q];hi[k]=highs[q];k+=1
                if q==i:i+=1
                else:j+=1
            while i<m:lo[k]=lows[i];hi[k]=highs[i];i+=1;k+=1
            while j<e:lo[k]=lows[j];hi[k]=highs[j];j+=1;k+=1
            for z in range(s,e):lows[z]=lo[z];highs[z]=hi[z]
        width*=2
    var chain=InlineArray[Int64,256](fill=0);var clen=0
    for p in range(pairs):chain[clen]=lows[p];clen+=1
    if pairs>0:chain[clen]=highs[pairs-1];clen+=1
    if Int(n)%2==1:mis_binary(mut chain,mut clen,v[Int(n)-1])
    for p in range(max(pairs-1,0)):mis_binary(mut chain,mut clen,highs[p])
    for i in range(Int(n)):v[i]=chain[i]
