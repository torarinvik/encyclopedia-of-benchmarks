from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn map_hash(key:Int64,cap:Int)->Int:
    let bits=bitcast[UInt32](Int32(key))&UInt32(0x7fffffff)
    return Int(bits%UInt32(cap))
fn map_find(keys:InlineArray[Int64,128],occ:InlineArray[Int64,128],cap:Int,key:Int64)->Int:
    var i=map_hash(key,cap)
    for _ in range(cap):
        if occ[i]==0:return cap
        if keys[i]==key:return i
        i=(i+1)%cap
    return cap
fn map_resize(mut keys:InlineArray[Int64,128],mut vals:InlineArray[Int64,128],mut occ:InlineArray[Int64,128],mut cap:Int,newcap:Int):
    let oldk=keys;let oldv=vals;let oldo=occ;let oldcap=cap;cap=newcap
    for i in range(newcap):occ[i]=0
    for j in range(oldcap):
        if oldo[j]!=0:
            var i=map_hash(oldk[j],newcap)
            while occ[i]!=0:i=(i+1)%newcap
            keys[i]=oldk[j];vals[i]=oldv[j];occ[i]=1
fn map_put(mut keys:InlineArray[Int64,128],mut vals:InlineArray[Int64,128],mut occ:InlineArray[Int64,128],mut cap:Int,mut size:Int,key:Int64,value:Int64):
    if size>cap/2:map_resize(keys,vals,occ,cap,cap*2)
    var i=map_hash(key,cap)
    while occ[i]!=0:
        if keys[i]==key:vals[i]=value;return
        i=(i+1)%cap
    keys[i]=key;vals[i]=value;occ[i]=1;size+=1
fn map_delete(mut keys:InlineArray[Int64,128],mut vals:InlineArray[Int64,128],mut occ:InlineArray[Int64,128],mut cap:Int,mut size:Int,key:Int64)->Bool:
    var i=map_find(keys,occ,cap,key)
    if i==cap:return False
    occ[i]=0;vals[i]=0;i=(i+1)%cap
    while occ[i]!=0:
        let k=keys[i];let val=vals[i];occ[i]=0;vals[i]=0;size-=1;map_put(keys,vals,occ,cap,size,k,val);i=(i+1)%cap
    size-=1
    if size>0 and size<=cap/8:map_resize(keys,vals,occ,cap,cap/2)
    return True
fn map_put_word(out:UnsafePointer[UInt8,MutAnyOrigin],slot:Int,x:Int64):
    let bits=UInt64(x)
    for j in range(8):out[slot*8+j]=UInt8((bits>>(8*j))&255)
@export("linear_probing_hash_map")
fn linear_probing_hash_map(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capout:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>98:return -1
    if v[0]<4 or v[0]>16 or v[1]<0 or v[1]>32 or n>c_size_t(2+3*v[1]):return -1
    var keys=InlineArray[Int64,128](fill=0);var vals=InlineArray[Int64,128](fill=0);var occ=InlineArray[Int64,128](fill=0);var capacity=Int(v[0]);var size=0;var words=InlineArray[Int64,320](fill=0);var wc=0;var pos=2
    for _ in range(Int(v[1])):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos+1>=Int(n):return -1
            let key=v[pos];let value=v[pos+1];pos+=2
            if key < -2147483648 or key>2147483647 or value < -2147483648 or value>2147483647:return -1
            map_put(keys,vals,occ,capacity,size,key,value);words[wc]=0;words[wc+1]=1;wc+=2
        elif op>=1 and op<=3:
            if pos>=Int(n):return -1
            let key=v[pos];pos+=1
            if key < -2147483648 or key>2147483647:return -1
            let slot=map_find(keys,occ,capacity,key)
            if op==1:
                words[wc]=1;words[wc+1]=if slot==capacity:1 else:0;wc+=2
                if slot==capacity:words[wc]=0
                else:words[wc]=vals[slot]
                wc+=1
            elif op==2:
                words[wc]=2;words[wc+1]=Int64(map_delete(keys,vals,occ,capacity,size,key));wc+=2
            else:words[wc]=3;words[wc+1]=Int64(slot!=capacity);wc+=2
        elif op==4:words[wc]=4;words[wc+1]=Int64(size);wc+=2
        elif op==5:
            var sorted=InlineArray[Int64,32](fill=0);var count=0
            for i in range(capacity):
                if occ[i]!=0:sorted[count]=keys[i];count+=1
            for i in range(1,count):
                let x=sorted[i];var j=i
                while j>0 and sorted[j-1]>x:sorted[j]=sorted[j-1];j-=1
                sorted[j]=x
            words[wc]=5;words[wc+1]=Int64(count);wc+=2
            for i in range(count):words[wc]=sorted[i];wc+=1
        else:return -1
    if pos!=Int(n) or wc>320:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capout<c_size_t(wc*8):return -2
    for i in range(wc):map_put_word(out,i,words[i])
    return Int64(wc*8)
