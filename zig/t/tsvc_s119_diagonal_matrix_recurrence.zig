// Clean-room TSVC s119 profile; see package rights note.
const MAX_SIDE:i64=8;const MAX_CELLS:usize=64;const MAX_INPUT_LENGTH:usize=130;
fn put64(out:[*c]u8,pos:usize,v:i64)void{const b:u64=@bitCast(v);for(0..8)|j|out[pos+j]=@truncate(b>>@intCast(8*j));}
pub export fn tsvc_s119_diagonal_matrix_recurrence(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<10 or length>MAX_INPUT_LENGTH)return -1;const values=input[0..length];const sr=values[0];const pr=values[1];if(sr<2 or sr>MAX_SIDE or pr<1 or pr>4)return -1;const n:usize=@intCast(sr);const passes:usize=@intCast(pr);const cells=n*n;if(length!=2+2*cells)return -1;
 var a=[_]i64{0}**MAX_CELLS;var b=[_]i64{0}**MAX_CELLS;for(0..cells)|i|{const av=values[2+i];const bv=values[2+cells+i];if(av< -2 or av>2 or bv< -2 or bv>2)return -1;a[i]=av;b[i]=bv;}
 const bytes=8*cells;if(output==null or capacity<bytes)return -2;for(0..passes)|_|{for(1..n)|i|{for(1..n)|j|{a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j];}}}for(0..cells)|i|put64(output,8*i,a[i]);return @intCast(cells);
}
