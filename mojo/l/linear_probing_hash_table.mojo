from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn table_find(t:InlineArray[Int64,128],cap:Int,key:Int64)->Int:
    var i=Int(key)%cap
    for _ in range(cap):
        if t[i]==0:return -1
        if t[i]==key:return i
        i=(i+1)%cap
    return -1
fn table_insert_slot(t:InlineArray[Int64,128],cap:Int,key:Int64)->Int:
    var i=Int(key)%cap
    for _ in range(cap):
        if t[i]==0 or t[i]==-1:return i
        i=(i+1)%cap
    return -1
fn table_rehash(mut t:InlineArray[Int64,128],mut cap:Int):
    let old=t;let oldcap=cap;cap*=2
    for i in range(cap):t[i]=0
    for i in range(oldcap):
        let key=old[i]
        if key>0:
            let slot=table_insert_slot(t,cap,key)
            if slot>=0:t[slot]=key
@export("linear_probing_hash_table")
fn linear_probing_hash_table(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capout:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    if v[0]<2 or v[0]>16 or v[1]<0 or v[1]>32:return -1
    var tablecap=Int(v[0]);let ops=Int(v[1]);var table=InlineArray[Int64,128](fill=0);var words=InlineArray[Int64,1088](fill=0);var wc=0;var size=0;var pos=2
    for _ in range(ops):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op>=0 and op<=3:
            if pos>=Int(n):return -1
            let key=v[pos];pos+=1
            if key<1 or key>2147483520:return -1
            if op==0:
                let slot=table_insert_slot(table,tablecap,key)
                if slot<0:return -1
                table[slot]=key;size+=1;words[wc]=0;words[wc+1]=1;wc+=2
                if size*2>=tablecap:table_rehash(table,tablecap)
            elif op==1:
                let slot=table_find(table,tablecap,key)
                if slot<0:return -1
                table[slot]=-1;size-=1;words[wc]=1;words[wc+1]=1;wc+=2
            elif op==2:words[wc]=2;words[wc+1]=Int64(table_find(table,tablecap,key)>=0);wc+=2
            else:words[wc]=3;words[wc+1]=key;wc+=2
        elif op==4:
            words[wc]=4;words[wc+1]=Int64(tablecap);wc+=2
            for i in range(tablecap):words[wc]=if table[i]==0:-2 else:table[i];wc+=1
        else:return -1
    if pos!=Int(n):return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capout<c_size_t(wc*8):return -2
    for i in range(wc):
        let x=UInt64(words[i])
        for j in range(8):out[i*8+j]=UInt8((x>>(8*j))&255)
    return Int64(wc*8)
