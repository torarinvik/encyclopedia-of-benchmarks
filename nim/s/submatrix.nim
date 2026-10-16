proc feed(h0:uint64,x:int64):uint64=
 var h=h0;let u=cast[uint64](x)
 for b in 0..7:h=(h xor ((u shr (8*b)) and 255'u64))*%0x100000001b3'u64
 h
proc submatrix*(v:ptr int64,n:uint64):int64 {.cdecl,exportc.}=
 if v==nil or n<6 or n>70:return -1
 let rows=v[0];let cols=v[1];let rs=v[2];let cs=v[3];let nr=v[4];let nc=v[5]
 if rows<1 or rows>8 or cols<1 or cols>8 or rows*cols>64 or n!=uint64(6+rows*cols):return -1
 if rs<0 or rs>rows or cs<0 or cs>cols or nr<0 or nr>rows or nc<0 or nc>cols or rs+nr>rows or cs+nc>cols:return -1
 for i in 6..<int(n):if v[i]< -2147483648'i64 or v[i]>2147483647'i64:return -1
 var h=feed(0xcbf29ce484222325'u64,nr);h=feed(h,nc)
 for r in 0..<int(nr):for c in 0..<int(nc):h=feed(h,v[6+(int(rs)+r)*int(cols)+int(cs)+c])
 cast[int64](h)
