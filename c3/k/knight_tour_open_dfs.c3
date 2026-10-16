module knight_tour_open_dfs;
const int[8] DR={2,1,-1,-2,-2,-1,1,2};
const int[8] DC={1,2,2,1,-1,-2,-2,-1};
fn bool solve(int* board,int row,int col,int step){if(step==64)return true;for(int mv=0;mv<8;mv++){int r=row+DR[mv],c=col+DC[mv];if(r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==-1){board[r*8+c]=step;if(solve(board,r,c,step+1))return true;board[r*8+c]=-1;}}return false;}
fn void put_i64(char* output,usz index,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){output[index*8+b]=(char)(bits&255);bits>>=8;}}
fn long knight_tour_open_dfs(long* input,usz length,char* output,usz capacity) @export("knight_tour_open_dfs"){
    if(length!=0)return -1;if(output==null||capacity<512)return -2;int[64] board;for(int i=0;i<64;i++)board[i]=-1;board[0]=0;if(!solve(&board[0],0,0,1))return -1;long[64] path;for(int row=0;row<8;row++)for(int col=0;col<8;col++)path[board[row*8+col]]=row*8+col;for(usz i=0;i<64;i++)put_i64(output,i,path[i]);return 512;
}
