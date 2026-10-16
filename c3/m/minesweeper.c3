module minesweeper;
const usz MAX_DIM=32;
const usz MAX_CELLS=1024;
const usz MAX_OUTPUT=8200;
fn usz write_i64(char* out,usz pos,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[pos++]=(char)(bits&255);bits>>=8;}return pos;}
fn long minesweeper(long* input,usz length,char* output,usz capacity) @export("minesweeper") {
    if(input==null||length<2||length>2+MAX_CELLS)return -1;
    long rows_value=input[0],cols_value=input[1];if(rows_value<1||rows_value>32||cols_value<1||cols_value>32)return -1;
    usz rows=(usz)rows_value,cols=(usz)cols_value,count=rows*cols;if(length!=2+count)return -1;
    uint8[MAX_CELLS] cells;for(usz i=0;i<count;i++){long value=input[2+i];if(value!=0&&value!=1)return -1;cells[i]=(uint8)value;}
    long[MAX_CELLS] neighbors;
    for(usz row=0;row<rows;row++)for(usz col=0;col<cols;col++){
        long mines=0;for(int dr=-1;dr<=1;dr++)for(int dc=-1;dc<=1;dc++){
            if(dr==0&&dc==0)continue;long nr=(long)row+dr,nc=(long)col+dc;
            if(nr>=0&&nr<(long)rows&&nc>=0&&nc<(long)cols&&cells[(usz)nr*cols+(usz)nc]==1)mines++;
        }neighbors[row*cols+col]=mines;
    }
    usz needed=8+8*count;if(output==null||capacity<needed)return -2;
    usz written=write_i64(output,0,(long)count);for(usz i=0;i<count;i++)written=write_i64(output,written,neighbors[i]);return (long)written;
}
