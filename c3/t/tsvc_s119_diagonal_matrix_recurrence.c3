// Clean-room TSVC s119 profile; see package rights note.
module tsvc_s119_diagonal_matrix_recurrence;
const int MAX_SIDE=8; const usz MAX_CELLS=64, MAX_INPUT_LENGTH=130;
fn void put64(char* o,usz p,long v){ulong b=(ulong)v;for(usz j=0;j<8;j++){o[p+j]=(char)(b&255);b>>=8;}}
fn long tsvc_s119_diagonal_matrix_recurrence(long* in,usz len,char* out,usz cap) @export("tsvc_s119_diagonal_matrix_recurrence"){
 if(in==null||len<10||len>MAX_INPUT_LENGTH)return -1;if(in[0]<2||in[0]>MAX_SIDE||in[1]<1||in[1]>4)return -1;
 usz n=in[0].usz(),passes=in[1].usz(),cells=n*n;if(len!=2+2*cells)return -1;long[MAX_CELLS] a,b;
 for(usz i=0;i<cells;i++){long av=in[2+i],bv=in[2+cells+i];if(av< -2||av>2||bv< -2||bv>2)return -1;a[i]=av;b[i]=bv;}
 usz bytes=8*cells;if(out==null||cap<bytes)return -2;for(usz p=0;p<passes;p++)for(usz i=1;i<n;i++)for(usz j=1;j<n;j++)a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j];
 for(usz i=0;i<cells;i++)put64(out,8*i,a[i]);return cells.long();
}
