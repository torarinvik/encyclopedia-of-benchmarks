// Clean-room TSVC s232 profile; see package rights note.
module tsvc_s232_triangular_row_square_recurrence;
fn void put64(&usz o,usz p,long v){usz b=(usz)v;for(usz k=0;k<8;k++){o[k]=(u8)(b&255);b>>=8;}}
fn long tsvc_s232_triangular_row_square_recurrence(&long in,usz len,&u8 out,usz cap){if(in==null||len<9||len>51)return -1;long nr=in[0];if(nr<2||nr>5)return -1;usz n=(usz)nr,nn=n*n;if(len!=1+2*nn)return -1;long a[25];long b[25];for(usz i=0;i<nn;i++){long x=in[1+i],y=in[1+nn+i];if(x< -1||x>1||y< -1||y>1)return -1;a[i]=x;b[i]=y;}if(out==null||cap<8*nn)return -2;for(usz j=1;j<n;j++)for(usz i=1;i<=j;i++){long x=a[j*n+i-1];a[j*n+i]=x*x+b[j*n+i];}for(usz i=0;i<nn;i++)put64(out+8*i,a[i]);return nn.long();}
