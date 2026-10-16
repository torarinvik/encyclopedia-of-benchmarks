#include <stddef.h>
#include <stdint.h>
typedef struct { int row,col,degree; } Move;
static const int DX[8]={1,2,2,1,-1,-2,-2,-1};
static const int DY[8]={-2,-1,1,2,2,1,-1,-2};
static int count_neighbors(const int board[8][8],int row,int col){int n=0;for(int i=0;i<8;++i){int r=row+DY[i],c=col+DX[i];if(r>=0&&r<8&&c>=0&&c<8&&board[r][c]==0)++n;}return n;}
static int neighbors(const int board[8][8],int row,int col,Move out[8]){int n=0;for(int i=0;i<8;++i){int r=row+DY[i],c=col+DX[i];if(r>=0&&r<8&&c>=0&&c<8&&board[r][c]==0)out[n++]=(Move){r,c,count_neighbors(board,r,c)};}return n;}
static void stable_sort(Move *moves,int n){for(int i=1;i<n;++i){Move value=moves[i];int j=i;while(j>0&&moves[j-1].degree>value.degree){moves[j]=moves[j-1];--j;}moves[j]=value;}}
static int orphan(const int board[8][8],int count,int row,int col){if(count<63){Move moves[8];int n=neighbors(board,row,col,moves);for(int i=0;i<n;++i)if(count_neighbors(board,moves[i].row,moves[i].col)==0)return 1;}return 0;}
static int solve(int board[8][8],int row,int col,int count){if(count>64)return 1;Move moves[8];int n=neighbors(board,row,col,moves);if(n==0&&count!=64)return 0;stable_sort(moves,n);for(int i=0;i<n;++i){Move m=moves[i];board[m.row][m.col]=count;if(!orphan(board,count,m.row,m.col)&&solve(board,m.row,m.col,count+1))return 1;board[m.row][m.col]=0;}return 0;}
static void put(uint8_t*out,size_t i,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[i*8+b]=(uint8_t)(bits>>(8*b));}
int64_t knights_tour_warnsdorff_open(const int64_t *input,size_t length,uint8_t *output,size_t capacity){if(length!=0)return -1;if(output==NULL||capacity<512)return -2;int board[8][8]={{0}};board[0][0]=1;if(!solve(board,0,0,2))return -1;int64_t path[64];for(int r=0;r<8;++r)for(int c=0;c<8;++c)path[board[r][c]-1]=r*8+c;for(size_t i=0;i<64;++i)put(output,i,path[i]);return 512;}
