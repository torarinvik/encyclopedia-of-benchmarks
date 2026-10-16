fn fill(board: &mut [i32; 256], width: usize, row: usize, col: usize, mr: usize, mc: usize, tile: &mut i32) {
    if width == 1 { return; }
    let h=width/2; let t=*tile; *tile+=1;
    let qr=[row,row,row+h,row+h]; let qc=[col,col+h,col,col+h];
    let cr=[row+h-1,row+h-1,row+h,row+h]; let cc=[col+h-1,col+h,col+h-1,col+h];
    let missing=if mr<row+h {if mc<col+h {0} else {1}} else if mc<col+h {2} else {3};
    for q in 0..4 {let (nr,nc)=if q==missing {(mr,mc)} else {board[cr[q]*16+cc[q]]=t;(cr[q],cc[q])};fill(board,h,qr[q],qc[q],nr,nc,tile);}
}
#[no_mangle]
pub extern "C" fn tiling_problem(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64 {
    if v.is_null()||n!=3{return -1;}let v=unsafe{std::slice::from_raw_parts(v,n)};let s=v[0];if !(1..=16).contains(&s)||(s&(s-1))!=0||v[1]<0||v[1]>=s||v[2]<0||v[2]>=s{return -1;}
    let size=s as usize;let mut board=[0i32;256];let mut tile=1;fill(&mut board,size,0,0,v[1] as usize,v[2] as usize,&mut tile);let bytes=size*size*4;if out.is_null()||cap<bytes{return -2;}
    for i in 0..size*size {let x=board[(i/size)*16+i%size].to_le_bytes();unsafe{std::ptr::copy_nonoverlapping(x.as_ptr(),out.add(i*4),4);}}bytes as i64
}
