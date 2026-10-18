module qr_eigen_values;

extern fn double sqrt(double value);
extern fn double fabs(double value);

const usz MAX_INPUT=6;
const usz MAX_ITERATIONS=256;
const double QR_TOLERANCE=1e-10;

fn bool finite_value(double x) { return x==x && x<1e300 && x> -1e300; }
fn double dot(double* a,double* b,usz length) {
    double total=0.0;
    for(usz i=0;i<length;i++) total+=a[i]*b[i];
    return total;
}
fn bool qr(double* matrix,double* q,double* r) {
    for(usz i=0;i<4;i++){q[i]=0.0;r[i]=0.0;}
    for(usz column=0;column<2;column++) {
        double[2] original={matrix[column],matrix[2+column]};
        double[2] residual={original[0],original[1]};
        for(usz previous=0;previous<column;previous++) {
            double[2] basis={q[previous],q[2+previous]};
            double denominator=dot(&basis[0],&basis[0],2);
            if(!finite_value(denominator)||denominator==0.0)return false;
            double scalar=dot(&original[0],&basis[0],2)/denominator;
            if(!finite_value(scalar))return false;
            for(usz row=0;row<2;row++) {
                residual[row]-=scalar*basis[row];if(!finite_value(residual[row]))return false;
            }
        }
        double norm_squared=dot(&residual[0],&residual[0],2);
        if(!finite_value(norm_squared)||norm_squared<=0.0)return false;
        double norm=sqrt(norm_squared);if(!finite_value(norm)||norm==0.0)return false;
        for(usz row=0;row<2;row++){q[row*2+column]=residual[row]/norm;if(!finite_value(q[row*2+column]))return false;}
        for(usz target=column;target<2;target++) {
            double[2] q_column={q[column],q[2+column]};
            double[2] matrix_column={matrix[target],matrix[2+target]};
            r[column*2+target]=dot(&q_column[0],&matrix_column[0],2);
            if(!finite_value(r[column*2+target]))return false;
        }
    }
    return true;
}

fn long qr_eigen_values(double* input,usz input_length,double* output,usz output_capacity)
    @export("qr_eigen_values") {
    if(input==null||input_length<1||input_length>MAX_INPUT)return -1L;
    if(!finite_value(input[0])||input[0]!=2.0||input_length!=5)return -1L;
    double[4] matrix=zeroed;
    for(usz i=0;i<4;i++) {
        double x=input[i+1];
        if(!finite_value(x)||x< -9.0||x>9.0||(double)(long)x!=x)return -1L;
        matrix[i]=x;
    }
    if(matrix[1]!=matrix[2]||matrix[1]==0.0||matrix[0]==matrix[3])return -1L;
    double last_eigenvalue=0.0;usz iterations=0;
    while(fabs(matrix[2])>QR_TOLERANCE) {
        if(iterations>=MAX_ITERATIONS)return -1L;
        last_eigenvalue=matrix[3];double[4] shifted=zeroed;
        for(usz i=0;i<4;i++) shifted[i]=matrix[i];
        shifted[0]-=last_eigenvalue;shifted[3]-=last_eigenvalue;
        double[4] q=zeroed,r=zeroed;
        if(!qr(&shifted[0],&q[0],&r[0]))return -1L;
        double[4] updated=zeroed;
        for(usz row=0;row<2;row++)for(usz column=0;column<2;column++)for(usz inner=0;inner<2;inner++)
            updated[row*2+column]+=r[row*2+inner]*q[inner*2+column];
        updated[0]+=last_eigenvalue;updated[3]+=last_eigenvalue;
        for(usz i=0;i<4;i++)if(!finite_value(updated[i]))return -1L;
        for(usz i=0;i<4;i++) matrix[i]=updated[i];
        iterations++;
    }
    double[2] staged={matrix[0],last_eigenvalue};
    if(!finite_value(staged[0])||!finite_value(staged[1]))return -1L;
    if(output==null||output_capacity<2)return -2L;
    output[0]=staged[0];output[1]=staged[1];return 2L;
}
