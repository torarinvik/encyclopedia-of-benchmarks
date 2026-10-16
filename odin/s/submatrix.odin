package submatrix
feed :: proc(h0:u64,x:i64)->u64{h:=h0;u:=transmute(u64,x);for b:=u32(0);b<8;b+=1{h=(h^((u>>(8*b))&255))*0x100000001b3};return h}
@(export)
submatrix :: proc "c" (v:[^]i64,n:u64)->i64{
 if v==nil||n<6||n>70 do return -1;rows,cols,rs,cs,nr,nc:=v[0],v[1],v[2],v[3],v[4],v[5];if rows<1||rows>8||cols<1||cols>8||rows*cols>64||n!=u64(6+rows*cols) do return -1;if rs<0||rs>rows||cs<0||cs>cols||nr<0||nr>rows||nc<0||nc>cols||rs+nr>rows||cs+nc>cols do return -1
 for i:=u64(6);i<n;i+=1{if v[i]< -2147483648||v[i]>2147483647 do return -1};h:=feed(u64(0xcbf29ce484222325),nr);h=feed(h,nc);for r:=i64(0);r<nr;r+=1{for c:=i64(0);c<nc;c+=1{h=feed(h,v[6+(rs+r)*cols+cs+c])}};return transmute(i64,h)
}
