from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn qph_find(table:InlineArray[Int64,64],capacity:Int,key:Int)->Int:
    for probe in range(100*capacity):
        let index=(key+probe*probe)%capacity;let value=table[index]
        if value==0:return -1
        if value==key:return index
    return -1
fn qph_insert(mut table:InlineArray[Int64,64],mut capacity:Int,mut size:Int,key:Int)->Bool:
    var slot= -1
    for probe in range(100*capacity):
        let index=(key+probe*probe)%capacity
        if table[index]==0 or table[index]== -1:slot=index;break
    if slot<0:return False
    table[slot]=key;size+=1
    if size*2>=capacity:return qph_rehash(table,capacity,size)
    return True
fn qph_rehash(mut table:InlineArray[Int64,64],mut capacity:Int,mut size:Int)->Bool:
    if capacity>32:return False
    let old=table;let old_capacity=capacity;capacity*=2
    table=InlineArray[Int64,64](fill=0);size=0
    for i in range(old_capacity):
        let key=old[i]
        if key!=0 and key!= -1:
            if not qph_insert(table,capacity,size,Int(key)):return False
    return True
@export("quadratic_probing_hash_table")
fn quadratic_probing_hash_table(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>51:return -1
    var capacity=Int(a[0]);let ops=Int(a[1])
    if capacity<1 or capacity>8 or ops<0 or ops>24 or n!=c_size_t(2+2*ops):return -1
    var slots=InlineArray[Int64,64](fill=0);var active=InlineArray[Bool,65](fill=False)
    var finds=InlineArray[Int64,24]();var find_count=0;var size=0
    for i in range(ops):
        let op=a[2+2*i];let key=a[3+2*i]
        if op<0 or op>2 or key<1 or key>64:return -1
        let k=Int(key)
        if op==0:
            if active[k] or not qph_insert(slots,capacity,size,k):return -1
            active[k]=True
        elif op==1:
            if not active[k]:return -1
            let index=qph_find(slots,capacity,k)
            if index<0:return -1
            slots[index]= -1;active[k]=False;size-=1
        else:
            let index=qph_find(slots,capacity,k)
            finds[find_count]=0 if index<=0 else slots[index];find_count+=1
    let words=3+find_count+capacity;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[Int64,75]();staged[0]=capacity;staged[1]=size;staged[2]=find_count
    for i in range(find_count):staged[3+i]=finds[i]
    for i in range(capacity):staged[3+find_count+i]=slots[i]
    for i in range(words):
        let bits=bitcast[UInt64](staged[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
