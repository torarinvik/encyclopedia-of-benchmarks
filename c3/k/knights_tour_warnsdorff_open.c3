module knights_tour_warnsdorff_open;
const int[8] DX={1,2,2,1,-1,-2,-2,-1};const int[8] DY={-2,-1,1,2,2,1,-1,-2};
struct Move{int row;int col;int degree;}
fn int count_neighbors(int* board,int row,int col){int n=0;for(int i=0;i<8;i++){int r=row+DY[i],c=col+DX[i];if(r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==0)n++;}return n;}
fn int neighbors(int* board,int row,int col,Move* out){int n=0;for(int i=0;i<8;i++){int r=row+DY[i],c=col+DX[i];if(r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==0){out[n].row=r;out[n].col=c;out[n].degree=count_neighbors(board,r,c);n++;}}for(int i=1;i<n;i++){Move value=out[i];int j=i;while(j>0&&out[j-1].degree>value.degree){out[j]=out[j-1];j--;}out[j]=value;}return n;}
fn bool orphan(int* board,int count,int row,int col){if(count<63){Move[8] moves;int n=neighbors(board,row,col,&moves[0]);for(int i=0;i<n;i++)if(count_neighbors(board,moves[i].row,moves[i].col)==0)return true;}return false;}
fn bool solve(int* board,int row,int col,int count){if(count>64)return true;Move[8] moves;int n=neighbors(board,row,col,&moves[0]);if(n==0&&count!=64)return false;for(int i=0;i<n;i++){Move m=moves[i];board[m.row*8+m.col]=count;if(!orphan(board,count,m.row,m.col)&&solve(board,m.row,m.col,count+1))return true;board[m.row*8+m.col]=0;}return false;}
fn void put_i64(char* out,usz index,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[index*8+b]=(char)(bits&255);bits>>=8;}}
fn long knights_tour_warnsdorff_open(long* input,usz length,char* output,usz capacity) @export("knights_tour_warnsdorff_open"){
    if(length!=0)return -1;if(output==null||capacity<512)return -2;int[64] board;for(int i=0;i<64;i++)board[i]=0;board[0]=1;if(!solve(&board[0],0,0,2))return -1;long[64] path;for(int r=0;r<8;r++)for(int c=0;c<8;c++)path[board[r*8+c]-1]=r*8+c;for(usz i=0;i<64;i++)put_i64(output,i,path[i]);return 512;
}
