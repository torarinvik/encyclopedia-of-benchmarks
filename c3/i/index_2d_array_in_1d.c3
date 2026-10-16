module index_2d_array_in_1d;
const long MAX_DIMENSION=32;
fn long index_2d_array_in_1d(long* input, usz length) @export("index_2d_array_in_1d") {
    if (input==null || length<4) return -1;
    long rows=input[0]; long cols=input[1]; long index=input[2];
    if (rows<1 || rows>MAX_DIMENSION || cols<1 || cols>MAX_DIMENSION) return -1;
    usz cells=(usz)(rows*cols);
    if (length!=cells+3 || index<0 || (usz)index>=cells) return -1;
    for (usz i=0;i<cells;i++) if (input[3+i]<0 || input[3+i]>1000000) return -1;
    usz row=(usz)index/(usz)cols; usz col=(usz)index%(usz)cols;
    return input[3+row*(usz)cols+col];
}
