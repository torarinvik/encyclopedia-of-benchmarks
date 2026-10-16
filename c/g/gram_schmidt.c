#include <stddef.h>
#include <stdint.h>

static void put_f64(uint8_t *out, size_t at, double x) {
    union { double f; uint64_t u; } bits = { .f = x };
    for (size_t b=0;b<8;b++) out[at+b]=(uint8_t)(bits.u>>(8*b));
}
int64_t gram_schmidt(const int64_t *v,size_t n,uint8_t *out,size_t cap) {
    if(!v||n<2||n>18)return -1;
    int64_t rows=v[0],dim=v[1];
    if(rows<1||rows>4||dim<rows||dim>4||n!=2+(size_t)(rows*dim))return -1;
    double a[4][4]={{0}},q[4][4]={{0}};
    for(int64_t i=0;i<rows;i++)for(int64_t j=0;j<dim;j++){
        int64_t x=v[2+i*dim+j]; if(x < -1000||x>1000)return -1;
        if(j<i&&x!=0)return -1; if(j==i&&(x<100||x>1000))return -1;
        a[i][j]=(double)x/1000.0;
    }
    size_t bytes=(size_t)(rows*dim)*8;if(!out||cap<bytes)return -2;
    for(int64_t k=0;k<rows;k++){
        for(int64_t j=0;j<dim;j++)q[k][j]=a[k][j];
        double projections[4]={0};
        for(int64_t i=0;i<k;i++){
            double dot=0,norm=0;for(int64_t j=0;j<dim;j++){dot+=a[k][j]*q[i][j];norm+=q[i][j]*q[i][j];}
            double factor=dot/norm;for(int64_t j=0;j<dim;j++)projections[j]+=q[i][j]*factor;
        }
        for(int64_t j=0;j<dim;j++)q[k][j]=a[k][j]-projections[j];
    }
    for(int64_t i=0;i<rows;i++)for(int64_t j=0;j<dim;j++)put_f64(out,(size_t)(i*dim+j)*8,q[i][j]);
    return (int64_t)bytes;
}
