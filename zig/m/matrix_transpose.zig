fn storeLe(out:[*]u8,off:usize,value:i64)void{const u:u64=@bitCast(value);for(0..8)|b|out[off+b]=@truncate(u>>(8*b));}
export fn matrix_transpose(v:[*c]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n<2 or n>1027)return -1;const r=v[0];const c=v[1];if(r<1 or r>32 or c<1 or c>32 or n!=2+@as(usize,@intCast(r*c)))return -1;const rows:usize=@intCast(r);const cols:usize=@intCast(c);var matrix=[_]i64{0}**MAX_CELLS;var result=[_]i64{0}**MAX_CELLS;for(0..rows*cols)|i|{const x=v[2+i];if(x < -2147483648 or x>2147483647)return -1;matrix[i]=x;}const orows:usize=cols;const ocols:usize=rows;
 for(0..rows)|i|{for(0..cols)|j|{const rr:usize=j;const cc:usize=i;result[rr*ocols+cc]=matrix[i*cols+j];}}
 const bytes=8*(2+orows*ocols);if(out==null or cap<bytes)return -2;storeLe(out,0,@intCast(orows));storeLe(out,8,@intCast(ocols));for(0..orows*ocols)|i|storeLe(out,16+8*i,result[i]);return @intCast(bytes);
}
const MAX_CELLS:usize=1024;
