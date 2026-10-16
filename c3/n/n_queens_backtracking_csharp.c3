module n_queens_backtracking_csharp;
const int MAX_N=8,MAX_OUTPUT_WORDS=737;
fn bool safe(int* rows,int col,int row){for(int c=0;c<col;c++){int prior=rows[c];if(prior==row||prior-c==row-col||prior+c==row+col)return false;}return true;}
fn void enumerate(int n,int col,int* rows,long* output,usz* used){if(col==n){for(int c=0;c<n;c++){output[*used]=rows[c];*used+=1;}output[0]+=1;return;}for(int row=0;row<n;row++)if(safe(rows,col,row)){rows[col]=row;enumerate(n,col+1,rows,output,used);}}
fn void put_i64(char* output,usz index,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){output[index*8+b]=(char)(bits&255);bits>>=8;}}
fn long n_queens_backtracking_csharp(long n,char* output,usz capacity) @export("n_queens_backtracking_csharp") {if(n<0||n>MAX_N)return -1;long[MAX_OUTPUT_WORDS] values;values[0]=0;usz used=1;if(n>0){int[MAX_N] rows;enumerate((int)n,0,&rows[0],&values[0],&used);}usz required=used*8;if(output==null||capacity<required)return -2;for(usz i=0;i<used;i++)put_i64(output,i,values[i]);return (long)required;}
