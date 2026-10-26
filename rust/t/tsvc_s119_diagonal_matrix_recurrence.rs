// Clean-room TSVC s119 profile; see package rights note.
const MAX_SIDE:i64=8;const MAX_CELLS:usize=64;const MAX_INPUT_LENGTH:usize=130;
fn put64(out:*mut u8,pos:usize,v:i64){let b=v as u64;for j in 0..8{unsafe{out.add(pos+j).write((b>>(8*j))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn tsvc_s119_diagonal_matrix_recurrence(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<10||length>MAX_INPUT_LENGTH{return -1;}let v=core::slice::from_raw_parts(input,length);
 if v[0]<2||v[0]>MAX_SIDE||v[1]<1||v[1]>4{return -1;}let n=v[0]as usize;let passes=v[1]as usize;let cells=n*n;if length!=2+2*cells{return -1;}
 let mut a=[0i64;MAX_CELLS];let mut b=[0i64;MAX_CELLS];for i in 0..cells{let av=v[2+i];let bv=v[2+cells+i];if !(-2..=2).contains(&av)||!(-2..=2).contains(&bv){return -1;}a[i]=av;b[i]=bv;}
 let bytes=8*cells;if output.is_null()||capacity<bytes{return -2;}for _ in 0..passes{for i in 1..n{for j in 1..n{a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j];}}}for i in 0..cells{put64(output,8*i,a[i]);}cells as i64
}
