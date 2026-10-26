// Clean-room TSVC s1119 profile; see package rights note.
module tsvc_s1119_same_column_matrix_prefix;
fn void put64(&usz o,usz p,long v){usz b=(usz)v;for(usz j=0;j<8;j++){o[j]=(u8)(b&255);b>>=8;}}
fn long tsvc_s1119_same_column_matrix_prefix(&long in,usz len,&u8 out,usz cap){if(in==null||len<10||len>130)return -1;long nr=in[0],passes=in[1];if(nr<2||nr>8||passes<1||passes>4)return -1;usz n=(usz)nr,nn=n*n;if(len!=2+2*nn)return -1;long a[64];long b[64];for(usz i=0;i<nn;i++){long x=in[2+i],y=in[2+nn+i];if(x< -1||x>1||y< -1||y>1)return -1;a[i]=x;b[i]=y;}if(out==null||cap<8*nn)return -2;for(usz p=0;p<(usz)passes;p++)for(usz i=1;i<n;i++)for(usz j=0;j<n;j++)a[i*n+j]=a[(i-1)*n+j]+b[i*n+j];for(usz i=0;i<nn;i++)put64(out+8*i,a[i]);return nn.long();}
