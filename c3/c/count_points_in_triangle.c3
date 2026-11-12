module count_points_in_triangle;

const usz MAX_N=24, MAX_M=24, MAX_Q=128, INPUT_MAX=483, BIT_STRIDE=MAX_M+1;
struct Point { long x; long y; }
struct Vector { long x; long y; }
struct Query { long a; long b; long c; }

fn int angle_half(Vector v) { if (v.y<0) return 0; if (v.y==0 && v.x>=0) return 1; return 2; }
fn bool angle_less(Vector a, Vector b) { int ha=angle_half(a),hb=angle_half(b); if(ha!=hb)return ha<hb; return a.x*b.y-a.y*b.x>0; }
fn bool direction_less(Vector a, Vector b) {
    if(angle_less(a,b))return true; if(angle_less(b,a))return false;
    long ra=a.x*a.x+a.y*a.y,rb=b.x*b.x+b.y*b.y; if(ra!=rb)return ra<rb;
    if(a.x!=b.x)return a.x<b.x; return a.y<b.y;
}
fn void sort_vectors(Vector* dirs, usz base, usz count) {
    for(usz i=1;i<count;i++){Vector item=dirs[base+i];usz j=i;while(j>0&&direction_less(item,dirs[base+j-1])){dirs[base+j]=dirs[base+j-1];j--;}dirs[base+j]=item;}
}
fn usz lower_ray(Vector* dirs, usz base, usz count, Vector ray) {
    usz low=0,high=count;while(low<high){usz mid=low+(high-low)/2;if(angle_less(dirs[base+mid],ray))low=mid+1;else high=mid;}return low;
}
fn usz upper_ray(Vector* dirs, usz base, usz count, Vector ray) {
    usz low=0,high=count;while(low<high){usz mid=low+(high-low)/2;if(!angle_less(ray,dirs[base+mid]))low=mid+1;else high=mid;}return low;
}
fn int fenwick_prefix(int* bit, usz base, usz end) { int total=0;while(end>0){total+=bit[base+end];end&=end-1;}return total; }
fn int arc_count(Vector* dirs, usz base, usz count, int* bit, usz bit_base, Vector start, Vector finish) {
    usz left=lower_ray(dirs,base,count,start),right=upper_ray(dirs,base,count,finish);
    if(!angle_less(finish,start))return fenwick_prefix(bit,bit_base,right)-fenwick_prefix(bit,bit_base,left);
    return fenwick_prefix(bit,bit_base,count)-fenwick_prefix(bit,bit_base,left)+fenwick_prefix(bit,bit_base,right);
}
fn int halfplane_count(usz u, usz v, Point* a, Vector* dirs, usz* counts, int* zeros, int* bit) {
    Vector edge={a[v].x-a[u].x,a[v].y-a[u].y};
    return zeros[u]+arc_count(dirs,u*MAX_M,counts[u],bit,u*BIT_STRIDE,{-edge.x,-edge.y},edge);
}
fn void store_le(uint8* output, usz offset, long value) { ulong bits=(ulong)value;for(usz byte=0;byte<8;byte++)output[offset+byte]=(uint8)((bits>>(8*byte))&255); }

fn long count_points_in_triangle(long* input, usz length, uint8* output, usz capacity) @export("count_points_in_triangle") {
    if(input==null||length<3||length>INPUT_MAX)return -1;
    long nr=input[0],mr=input[1],qr=input[2];if(nr<1||nr>(long)MAX_N||mr<1||mr>(long)MAX_M||qr<1||qr>(long)MAX_Q)return -1;
    usz n=(usz)nr,m=(usz)mr,q=(usz)qr;if(length!=3+2*n+2*m+3*q)return -1;
    Point[MAX_N] a=zeroed;Point[MAX_M] b=zeroed;Query[MAX_Q] queries=zeroed;usz cursor=3;
    for(usz i=0;i<n;i++){a[i]={input[cursor],input[cursor+1]};cursor+=2;if(a[i].x < -1000000000||a[i].x>1000000000||a[i].y < -1000000000||a[i].y>1000000000)return -1;}
    for(usz i=0;i<m;i++){b[i]={input[cursor],input[cursor+1]};cursor+=2;if(b[i].x < -1000000000||b[i].x>1000000000||b[i].y < -1000000000||b[i].y>1000000000)return -1;}
    for(usz i=0;i<q;i++){long ia=input[cursor],ib=input[cursor+1],ic=input[cursor+2];cursor+=3;if(ia<0||ia>=nr||ib<0||ib>=nr||ic<0||ic>=nr)return -1;queries[i]={ia,ib,ic};}
    usz required=8*q;if(output==null||capacity<required)return -2;
    Vector[MAX_N*MAX_M] dirs=zeroed;usz[MAX_N] counts=zeroed;int[MAX_N] zeros=zeroed;int[MAX_N*BIT_STRIDE] bit=zeroed;
    for(usz u=0;u<n;u++){
        for(usz j=0;j<m;j++){Vector v={b[j].x-a[u].x,b[j].y-a[u].y};if(v.x==0&&v.y==0)zeros[u]++;else{dirs[u*MAX_M+counts[u]]=v;counts[u]++;}}
        sort_vectors(&dirs[0],u*MAX_M,counts[u]);
        for(usz i=0;i<counts[u];i++){usz at=i+1;while(at<=counts[u]){bit[u*BIT_STRIDE+at]++;at+=at&(~at+1);}}
    }
    long[MAX_Q] answers=zeroed;
    for(usz qi=0;qi<q;qi++){
        usz ia=(usz)queries[qi].a,ib=(usz)queries[qi].b,ic=(usz)queries[qi].c;
        long orient=(a[ib].x-a[ia].x)*(a[ic].y-a[ia].y)-(a[ib].y-a[ia].y)*(a[ic].x-a[ia].x);
        if(orient==0){answers[qi]=0;continue;}if(orient<0){usz temp=ib;ib=ic;ic=temp;}
        int outside=halfplane_count(ia,ib,&a[0],&dirs[0],&counts[0],&zeros[0],&bit[0])+halfplane_count(ib,ic,&a[0],&dirs[0],&counts[0],&zeros[0],&bit[0])+halfplane_count(ic,ia,&a[0],&dirs[0],&counts[0],&zeros[0],&bit[0]);
        Vector bs={a[ib].x-a[ic].x,a[ib].y-a[ic].y},be={a[ib].x-a[ia].x,a[ib].y-a[ia].y};
        Vector cs={a[ic].x-a[ia].x,a[ic].y-a[ia].y},ce={a[ic].x-a[ib].x,a[ic].y-a[ib].y};
        Vector a_start={a[ia].x-a[ib].x,a[ia].y-a[ib].y},a_end={a[ia].x-a[ic].x,a[ia].y-a[ic].y};
        int pairs=zeros[ib]+arc_count(&dirs[0],ib*MAX_M,counts[ib],&bit[0],ib*BIT_STRIDE,bs,be)+zeros[ic]+arc_count(&dirs[0],ic*MAX_M,counts[ic],&bit[0],ic*BIT_STRIDE,cs,ce)+zeros[ia]+arc_count(&dirs[0],ia*MAX_M,counts[ia],&bit[0],ia*BIT_STRIDE,a_start,a_end);
        answers[qi]=(long)m-outside+pairs;
    }
    for(usz i=0;i<q;i++)store_le(output,8*i,answers[i]);return (long)required;
}
