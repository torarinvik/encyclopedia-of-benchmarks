#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input=6,max_iterations=256;
constexpr double qr_tolerance=1e-10;
double add(double a,double b) noexcept { volatile double v=a+b;return v; }
double sub(double a,double b) noexcept { volatile double v=a-b;return v; }
double mul(double a,double b) noexcept { volatile double v=a*b;return v; }
double divv(double a,double b) noexcept { volatile double v=a/b;return v; }
double dot(const double* a,const double* b,std::size_t n) noexcept {double total=0.0;for(std::size_t i=0;i<n;i++)total=add(total,mul(a[i],b[i]));return total;}
bool qr(const double matrix[4],double q[4],double r[4]) noexcept {
    for(std::size_t i=0;i<4;i++){q[i]=0.0;r[i]=0.0;}
    for(std::size_t column=0;column<2;column++){
        const double original[2]={matrix[column],matrix[2+column]};double residual[2]={original[0],original[1]};
        for(std::size_t previous=0;previous<column;previous++){
            const double basis[2]={q[previous],q[2+previous]};const double denominator=dot(basis,basis,2);
            if(!std::isfinite(denominator)||denominator==0.0)return false;
            const double scalar=divv(dot(original,basis,2),denominator);if(!std::isfinite(scalar))return false;
            for(std::size_t row=0;row<2;row++){residual[row]=sub(residual[row],mul(scalar,basis[row]));if(!std::isfinite(residual[row]))return false;}
        }
        const double norm_squared=dot(residual,residual,2);if(!std::isfinite(norm_squared)||norm_squared<=0.0)return false;
        const double norm=std::sqrt(norm_squared);if(!std::isfinite(norm)||norm==0.0)return false;
        for(std::size_t row=0;row<2;row++){q[row*2+column]=divv(residual[row],norm);if(!std::isfinite(q[row*2+column]))return false;}
        for(std::size_t target=column;target<2;target++){
            const double q_column[2]={q[column],q[2+column]},matrix_column[2]={matrix[target],matrix[2+target]};
            r[column*2+target]=dot(q_column,matrix_column,2);if(!std::isfinite(r[column*2+target]))return false;
        }
    }
    return true;
}
}

extern "C" std::int64_t qr_eigen_values(const double* input,std::size_t input_length,
    double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<1||input_length>max_input)return -1;
    if(!std::isfinite(input[0])||input[0]!=2.0||input_length!=5)return -1;
    double matrix[4];
    for(std::size_t i=0;i<4;i++){
        const double x=input[i+1];if(!std::isfinite(x)||x < -9.0||x>9.0||x!=static_cast<double>(static_cast<int>(x)))return -1;matrix[i]=x;
    }
    if(matrix[1]!=matrix[2]||matrix[1]==0.0||matrix[0]==matrix[3])return -1;
    double last_eigenvalue=0.0;std::size_t iterations=0;
    while(std::fabs(matrix[2])>qr_tolerance){
        if(iterations>=max_iterations)return -1;
        last_eigenvalue=matrix[3];double shifted[4]={matrix[0],matrix[1],matrix[2],matrix[3]};
        shifted[0]=sub(shifted[0],last_eigenvalue);shifted[3]=sub(shifted[3],last_eigenvalue);
        double q[4],r[4];if(!qr(shifted,q,r))return -1;
        double updated[4]={0.0,0.0,0.0,0.0};
        for(std::size_t row=0;row<2;row++)for(std::size_t column=0;column<2;column++)for(std::size_t inner=0;inner<2;inner++)
            updated[row*2+column]=add(updated[row*2+column],mul(r[row*2+inner],q[inner*2+column]));
        updated[0]=add(updated[0],last_eigenvalue);updated[3]=add(updated[3],last_eigenvalue);
        for(double value:updated)if(!std::isfinite(value))return -1;
        for(std::size_t i=0;i<4;i++)matrix[i]=updated[i];iterations++;
    }
    double staged[2]={matrix[0],last_eigenvalue};if(!std::isfinite(staged[0])||!std::isfinite(staged[1]))return -1;
    if(output==nullptr||output_capacity<2)return -2;
    output[0]=staged[0];output[1]=staged[1];return 2;
}
