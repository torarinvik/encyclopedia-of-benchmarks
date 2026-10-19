from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime LWW_MAPS=4
comptime LWW_KEYS=24
@export("lww_element_set")
fn lww_element_set(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>98 or v[0]<0 or v[0]>24 or n!=c_size_t(1+4*v[0]):return -1
    var keys=InlineArray[Int64,96](fill=0);var times=InlineArray[Int64,96](fill=0);var counts=InlineArray[Int64,4](fill=0);var mask:Int64=0;var look=0
    for opi in range(Int(v[0])):
        let p=1+4*opi;let op=v[p];let a=v[p+1];let b=v[p+2];let c=v[p+3]
        if op==0 or op==1:
            if a<0 or a>1 or b < -2147483648 or b>2147483647 or c < -2147483648 or c>2147483647:return -1
            let map=Int(a*2+(op==1));let base=map*LWW_KEYS;var pos=0
            while pos<Int(counts[map]) and keys[base+pos]!=b:pos+=1
            if pos==Int(counts[map]):
                if counts[map]>=LWW_KEYS:return -1
                keys[base+pos]=b;counts[map]+=1
            times[base+pos]=c
        elif op==2:
            if a<0 or a>1 or b < -2147483648 or b>2147483647 or c!=0:return -1
            let add=Int(a*2);let rem=add+1;var ap=0;var rp=0
            while ap<Int(counts[add]) and keys[add*LWW_KEYS+ap]!=b:ap+=1
            while rp<Int(counts[rem]) and keys[rem*LWW_KEYS+rp]!=b:rp+=1
            if ap<Int(counts[add]) and (rp==Int(counts[rem]) or times[add*LWW_KEYS+ap]>times[rem*LWW_KEYS+rp]):mask|=Int64(1)<<look
            look+=1
        elif op==3:
            if a<0 or a>1 or b<0 or b>1 or c!=0:return -1
            if a!=b:
                for kind in range(2):
                    let target=Int(a*2)+kind;let source=Int(b*2)+kind;var si=0
                    while si<Int(counts[source]):
                        let key=keys[source*LWW_KEYS+si];let time=times[source*LWW_KEYS+si];var ti=0
                        while ti<Int(counts[target]) and keys[target*LWW_KEYS+ti]!=key:ti+=1
                        if ti==Int(counts[target]):
                            if counts[target]>=LWW_KEYS:return -1
                            keys[target*LWW_KEYS+ti]=key;times[target*LWW_KEYS+ti]=time;counts[target]+=1
                        elif time>=times[target*LWW_KEYS+ti]:times[target*LWW_KEYS+ti]=time
                        si+=1
        else:return -1
    return mask
