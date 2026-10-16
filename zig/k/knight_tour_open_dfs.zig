const DR=[_]i32{2,1,-1,-2,-2,-1,1,2};
const DC=[_]i32{1,2,2,1,-1,-2,-2,-1};
fn solve(board:*[64]i32,row:i32,col:i32,step:i32)bool{if(step==64)return true;for(0..8)|mv|{const r=row+DR[mv];const c=col+DC[mv];if(r>=0 and r<8 and c>=0 and c<8){const index=@as(usize,@intCast(r*8+c));if(board[index]==-1){board[index]=step;if(solve(board,r,c,step+1))return true;board[index]= -1;}}}return false;}
fn put(out:[*c]u8,index:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[index*8+b]=@truncate(bits>>@intCast(8*b));}
pub export fn knight_tour_open_dfs(_input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(length!=0)return -1;if(output==null or capacity<512)return -2;var board=[_]i32{-1}**64;board[0]=0;if(!solve(&board,0,0,1))return -1;var path=[_]i64{0}**64;for(0..8)|r|for(0..8)|c|path[@intCast(board[r*8+c])]=@intCast(r*8+c);for(0..64)|i|put(output,i,path[i]);return 512;
}
