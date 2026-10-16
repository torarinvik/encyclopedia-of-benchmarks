const DR:[i32;8]=[2,1,-1,-2,-2,-1,1,2];
const DC:[i32;8]=[1,2,2,1,-1,-2,-2,-1];
fn solve(board:&mut[[i32;8];8],row:i32,col:i32,step:i32)->bool{if step==64{return true;}for mv in 0..8{let r=row+DR[mv];let c=col+DC[mv];if r>=0&&r<8&&c>=0&&c<8&&board[r as usize][c as usize]==-1{board[r as usize][c as usize]=step;if solve(board,r,c,step+1){return true;}board[r as usize][c as usize]=-1;}}false}
unsafe fn put(out:*mut u8,index:usize,value:i64){let bits=value as u64;for b in 0..8{*out.add(index*8+b)=(bits>>(8*b))as u8;}}
#[no_mangle]
pub unsafe extern "C" fn knight_tour_open_dfs(_input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if length!=0{return -1;}if output.is_null()||capacity<512{return -2;}let mut board=[[-1i32;8];8];board[0][0]=0;if !solve(&mut board,0,0,1){return -1;}let mut path=[0i64;64];for r in 0..8{for c in 0..8{path[board[r][c]as usize]=(r*8+c)as i64;}}for i in 0..64{put(output,i,path[i]);}512
}
