proc percentage*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "percentage".} =
 if v.isNil or n!=3 or v[0]<1 or v[0]>100000 or v[1]<1 or v[1]>100000 or v[2]<1 or v[2]>4:return -1
 var scale=1'i64
 for i in 0..<int(v[2]): scale *= 10
 let product=v[0]*v[1]*scale
 if product<100:return -1
 product div 100
