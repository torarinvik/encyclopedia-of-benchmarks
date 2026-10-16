module tiling_problem;
fn void fill(long* board, usz width, usz row, usz col, usz mr, usz mc, long* tile) {
    if (width == 1) return;
    usz h=width/2; long t=tile[0]; tile[0]=tile[0]+1;
    usz qr[4]={row,row,row+h,row+h}, qc[4]={col,col+h,col,col+h};
    usz cr[4]={row+h-1,row+h-1,row+h,row+h}, cc[4]={col+h-1,col+h,col+h-1,col+h};
    usz missing=mr<row+h?(mc<col+h?0:1):(mc<col+h?2:3);
    for(usz q=0;q<4;q++){usz nr=mr,nc=mc;if(q!=missing){board[cr[q]*16+cc[q]]=t;nr=cr[q];nc=cc[q];}fill(board,h,qr[q],qc[q],nr,nc,tile);}
}
fn long tiling_problem(long* v, usz n, char* output, usz cap) @export("tiling_problem") {
    if(v==null||n!=3||v[0]<1||v[0]>16||(v[0]&(v[0]-1))!=0||v[1]<0||v[1]>=v[0]||v[2]<0||v[2]>=v[0])return -1;
    long board[256]={},tile[1]={1};usz size=(usz)v[0];fill(board,size,0,0,(usz)v[1],(usz)v[2],tile);
    usz bytes=size*size*4;if(output==null||cap<bytes)return -2;
    for(usz i=0;i<size*size;i++){uint32 x=(uint32)board[(i/size)*16+i%size];for(usz b=0;b<4;b++)output[i*4+b]=(char)(x>>(8*b));}return (long)bytes;
}
