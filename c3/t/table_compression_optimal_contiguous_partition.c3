module table_compression_optimal_contiguous_partition;
const int MAX_ROWS=8;const int MAX_COLS=8;const int MAX_INPUT=66;const int OUTPUT=24;
fn int interval_cost(long* values,int rows,int cols,int begin,int end){int runs=0;bool have=false;long previous=0;for(int row=0;row<rows;row++)for(int col=begin;col<end;col++){long value=values[2+row*cols+col];if(!have||value!=previous)runs++;previous=value;have=true;}return 2*runs;}
fn void put_i64(char* output,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){output[at+i]=(char)(bits&255);bits>>=8;}}
fn long table_compression_optimal_contiguous_partition(long* values,usz length,char* output,usz capacity) @export("table_compression_optimal_contiguous_partition"){
 if(values==null||length<3||length>MAX_INPUT||values[0]<1||values[0]>MAX_ROWS||values[1]<1||values[1]>MAX_COLS)return -1;int rows=(int)values[0],cols=(int)values[1];if(length!=(usz)(2+rows*cols))return -1;for(int i=0;i<rows*cols;i++)if(values[2+i]<0||values[2+i]>15)return -1;
 int[MAX_COLS+1] cost={};int[MAX_COLS+1] previous={};for(int end=1;end<=cols;end++){cost[end]=0x3fffffff;for(int start=0;start<end;start++){int candidate=cost[start]+interval_cost(values,rows,cols,start,end);if(candidate<cost[end]){cost[end]=candidate;previous[end]=start;}}}
 int groups=0;ulong cuts=0;int end=cols;while(end>0){int start=previous[end];if(start>0)cuts|=(ulong)1<<(start-1);groups++;end=start;}char[OUTPUT] staged={};put_i64(staged,0,(long)cost[cols]);put_i64(staged,8,(long)groups);put_i64(staged,16,(long)cuts);if(output==null||capacity<OUTPUT)return -2;for(usz i=0;i<OUTPUT;i++)output[i]=staged[i];return OUTPUT;
}
