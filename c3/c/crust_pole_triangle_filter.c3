module crust_pole_triangle_filter;

const int MAX_FACETS=16,MAX_VERTICES=12;
fn void put_i64(char* out,usz word,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[word*8+b]=(char)((bits>>(8*b))&255);}
fn bool tri_less(long* a,long* b){for(int i=0;i<3;i++){if(a[i]<b[i])return true;if(a[i]>b[i])return false;}return false;}
fn bool tri_equal(long* a,long* b){return a[0]==b[0]&&a[1]==b[1]&&a[2]==b[2];}

fn long crust_pole_triangle_filter(long* input,usz input_length,char* output,usz output_capacity) @export("crust_pole_triangle_filter"){
    if(input==null||input_length<3||input_length>51)return -1;
    long ns0=input[0],np0=input[1],nf0=input[2];
    if(ns0<3||ns0>8||np0<1||np0>4||ns0+np0>MAX_VERTICES||nf0<0||nf0>MAX_FACETS||input_length!=(usz)(3+3*nf0))return -1;
    int ns=(int)ns0,total=(int)(ns0+np0),nf=(int)nf0;long[MAX_FACETS*3] facets={0};int count=0;
    for(int i=0;i<nf;i++){
        long[3] tri={input[3+3*i],input[4+3*i],input[5+3*i]};
        if(tri[0]<0||tri[0]>=total||tri[1]<0||tri[1]>=total||tri[2]<0||tri[2]>=total||tri[0]==tri[1]||tri[0]==tri[2]||tri[1]==tri[2])return -1;
        if(tri[0]>=ns||tri[1]>=ns||tri[2]>=ns)continue;
        for(int a=1;a<3;a++){long x=tri[a];int j=a;while(j>0&&tri[j-1]>x){tri[j]=tri[j-1];j--;}tri[j]=x;}
        bool duplicate=false;for(int j=0;j<count;j++)if(facets[j*3]==tri[0]&&facets[j*3+1]==tri[1]&&facets[j*3+2]==tri[2])duplicate=true;
        if(!duplicate){for(int j=0;j<3;j++)facets[count*3+j]=tri[j];count++;}
    }
    for(int i=1;i<count;i++){long[3] x={facets[i*3],facets[i*3+1],facets[i*3+2]};int j=i;while(j>0&&tri_less(&x[0],&facets[(j-1)*3])){for(int z=0;z<3;z++)facets[j*3+z]=facets[(j-1)*3+z];j--;}for(int z=0;z<3;z++)facets[j*3+z]=x[z];}
    usz bytes=(usz)(1+3*count)*8;if(output==null||output_capacity<bytes)return -2;put_i64(output,0,count);usz at=1;
    for(int i=0;i<count;i++)for(int j=0;j<3;j++)put_i64(output,at++,facets[i*3+j]);return (long)bytes;
}
