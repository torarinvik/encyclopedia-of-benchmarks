#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 6u
#define QR_TOLERANCE 1e-10
#define MAX_ITERATIONS 256u

static double add(double a,double b){volatile double v=a+b;return v;}
static double sub(double a,double b){volatile double v=a-b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static double divv(double a,double b){volatile double v=a/b;return v;}
static double dot(const double *a,const double *b,size_t n){double total=0.0;for(size_t i=0;i<n;i++)total=add(total,mul(a[i],b[i]));return total;}

static int qr(const double matrix[4],double q[4],double r[4])
{
    for(size_t i=0;i<4;i++){q[i]=0.0;r[i]=0.0;}
    for(size_t column=0;column<2;column++){
        double original[2]={matrix[column],matrix[2+column]};
        double residual[2]={original[0],original[1]};
        for(size_t previous=0;previous<column;previous++){
            double basis[2]={q[previous],q[2+previous]};
            double denominator=dot(basis,basis,2);
            if(!isfinite(denominator)||denominator==0.0)return 0;
            double scalar=divv(dot(original,basis,2),denominator);
            if(!isfinite(scalar))return 0;
            for(size_t row=0;row<2;row++){
                residual[row]=sub(residual[row],mul(scalar,basis[row]));
                if(!isfinite(residual[row]))return 0;
            }
        }
        double norm_squared=dot(residual,residual,2);
        if(!isfinite(norm_squared)||norm_squared<=0.0)return 0;
        double norm=sqrt(norm_squared);
        if(!isfinite(norm)||norm==0.0)return 0;
        for(size_t row=0;row<2;row++){
            q[row*2+column]=divv(residual[row],norm);
            if(!isfinite(q[row*2+column]))return 0;
        }
        for(size_t target=column;target<2;target++){
            double q_column[2]={q[column],q[2+column]};
            double matrix_column[2]={matrix[target],matrix[2+target]};
            r[column*2+target]=dot(q_column,matrix_column,2);
            if(!isfinite(r[column*2+target]))return 0;
        }
    }
    return 1;
}

int64_t qr_eigen_values(const double *input,size_t input_length,double *output,size_t output_capacity)
{
    if(input==NULL||input_length<1||input_length>MAX_INPUT)return -1;
    if(!isfinite(input[0])||input[0]!=2.0||input_length!=5)return -1;
    double matrix[4];
    for(size_t i=0;i<4;i++){
        double x=input[i+1];
        if(!isfinite(x)||x< -9.0||x>9.0||x!=(double)(int)x)return -1;
        matrix[i]=x;
    }
    if(matrix[1]!=matrix[2]||matrix[1]==0.0||matrix[0]==matrix[3])return -1;
    double last_eigenvalue=0.0;size_t iterations=0;
    while(fabs(matrix[2])>QR_TOLERANCE){
        if(iterations>=MAX_ITERATIONS)return -1;
        last_eigenvalue=matrix[3];
        double shifted[4]={matrix[0],matrix[1],matrix[2],matrix[3]};
        shifted[0]=sub(shifted[0],last_eigenvalue);shifted[3]=sub(shifted[3],last_eigenvalue);
        double q[4],r[4];if(!qr(shifted,q,r))return -1;
        double updated[4]={0.0,0.0,0.0,0.0};
        for(size_t row=0;row<2;row++)for(size_t column=0;column<2;column++)for(size_t inner=0;inner<2;inner++)
            updated[row*2+column]=add(updated[row*2+column],mul(r[row*2+inner],q[inner*2+column]));
        updated[0]=add(updated[0],last_eigenvalue);updated[3]=add(updated[3],last_eigenvalue);
        for(size_t i=0;i<4;i++)if(!isfinite(updated[i]))return -1;
        for(size_t i=0;i<4;i++)matrix[i]=updated[i];
        iterations++;
    }
    double staged[2]={matrix[0],last_eigenvalue};
    if(!isfinite(staged[0])||!isfinite(staged[1]))return -1;
    if(output==NULL||output_capacity<2)return -2;
    output[0]=staged[0];output[1]=staged[1];return 2;
}
