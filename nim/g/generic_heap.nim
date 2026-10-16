proc hashv(h0:uint64,v:int64):uint64 =
  var h=h0;let bits=cast[uint64](v)
  for i in 0..7:h=(h xor ((bits shr (8*i)) and 255'u64))*0x100000001b3'u64
  h
proc generic_heap*(a:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"generic_heap".} =
  if a==nil or n<1 or n>769:return -1
  if a[0]<0 or a[0]>256 or n!=csize_t(1+3*a[0]):return -1
  var ids:array[128,int64];var ps:array[128,int64];var pos:array[4096,int32];for i in 0..<4096:pos[i] = -1
  var z=0;var h=0xcbf29ce484222325'u64
  for k in 0..<int(a[0]):
    let op=a[1+3*k];let id=a[2+3*k];let v=a[3+3*k]
    if op==0:
      if id<0 or id>=4096 or v< -2147483648 or v>2147483647 or pos[int(id)]>=0 or z>=128:return -1
      ids[z]=id;ps[z]=v;pos[int(id)]=int32(z);var i=z;z+=1
      while i>0:
        let q=(i-1) div 2;if ps[i]<=ps[q]:break
        swap(ids[i],ids[q]);swap(ps[i],ps[q]);pos[int(ids[i])]=int32(i);pos[int(ids[q])]=int32(q);i=q
    elif op==1 or op==2:
      if id!=0 or v!=0 or z==0:return -1
      let ri=ids[0];let rv=ps[0]
      if op==2:
        swap(ids[0],ids[z-1]);swap(ps[0],ps[z-1]);pos[int(ids[0])]=0;pos[int(ids[z-1])]=int32(z-1);z-=1;pos[int(ri)]= -1
        if z>0:
          var i=0
          while 2*i+1<z:
            var q=2*i+1;if q+1<z and ps[q+1]>ps[q]:q+=1
            if ps[i]>=ps[q]:break
            swap(ids[i],ids[q]);swap(ps[i],ps[q]);pos[int(ids[i])]=int32(i);pos[int(ids[q])]=int32(q);i=q
      h=hashv(hashv(h,ri),rv)
    elif op==3:
      if id<0 or id>=4096 or v< -2147483648 or v>2147483647 or pos[int(id)]<0:return -1
      var i=int(pos[int(id)]);ps[i]=v
      while i>0:
        let q=(i-1) div 2;if ps[i]<=ps[q]:break
        swap(ids[i],ids[q]);swap(ps[i],ps[q]);pos[int(ids[i])]=int32(i);pos[int(ids[q])]=int32(q);i=q
    elif op==4 or op==5:
      if id!=0 or v!=0:return -1
      h=hashv(h,if op==4:int64(z) else:int64(z==0))
    else:return -1
  cast[int64](h)
