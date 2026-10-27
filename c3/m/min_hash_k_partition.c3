module min_hash_k_partition;
const long K=8,N=32,EMPTY=1001;
fn void put_i64(char* out,usz pos,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[pos+b]=(char)((bits>>(8*b))&255);}
fn long min_hash_k_partition(long* input,usz length,char* output,usz capacity) @export("min_hash_k_partition"){
 if(input==null||length<2||length>66)return -1;long k0=input[0],n0=input[1];if(k0<1||k0>K||n0<0||n0>N||length!=2+(2*n0).usz())return -1;
 long[K] ids,ranks;for(int b=0;b<k0.int();b++){ids[b]=-1;ranks[b]=EMPTY;}
 for(int id=0;id<n0.int();id++){long bucket=input[2+2*id],rank=input[3+2*id];if(bucket<0||bucket>=k0||rank<0||rank>1000)return -1;int b=bucket.int();if(ids[b]<0||rank<ranks[b]||(rank==ranks[b]&&id.long()<ids[b])){ids[b]=id.long();ranks[b]=rank;}}
 long[2*K] staged;for(int b=0;b<k0.int();b++){staged[2*b]=ids[b];staged[2*b+1]=ranks[b];}
 usz required=(2*k0).usz()*8;if(output==null||capacity<required)return -2;for(usz i=0;i<(2*k0).usz();i++)put_i64(output,i*8,staged[i]);return required.long();
}
