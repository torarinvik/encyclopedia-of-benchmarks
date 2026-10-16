fn feed(h0:u64,x:i64)u64{var h=h0;const u=@as(u64,@bitCast(x));for(0..8)|b|{h=(h^((u>>(8*b))&255))*%0x100000001b3;}return h;}
export fn submatrix(v:[*]const i64,n:usize)i64{
 if(n<6 or n>70)return -1;const rows=v[0];const cols=v[1];const rs=v[2];const cs=v[3];const nr=v[4];const nc=v[5];if(rows<1 or rows>8 or cols<1 or cols>8 or rows*cols>64 or n!=@as(usize,@intCast(6+rows*cols)))return -1;if(rs<0 or rs>rows or cs<0 or cs>cols or nr<0 or nr>rows or nc<0 or nc>cols or rs+nr>rows or cs+nc>cols)return -1;for(6..n)|i|{if(v[i]<-2147483648 or v[i]>2147483647)return -1;}
 var h=feed(0xcbf29ce484222325,@as(i64,nr));h=feed(h,nc);for(0..@as(usize,@intCast(nr)))|r|{for(0..@as(usize,@intCast(nc)))|c|{const ix=6+(@as(usize,@intCast(rs))+r)*@as(usize,@intCast(cols))+@as(usize,@intCast(cs))+c;h=feed(h,v[ix]);}}return @bitCast(h);
}
