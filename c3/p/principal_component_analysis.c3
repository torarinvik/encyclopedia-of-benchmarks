module principal_component_analysis;

extern fn double sqrt(double value);

const usz MAX_SAMPLES=8;
const usz MAX_FEATURES=4;
const usz MAX_INPUT=35;
const usz MAX_OUTPUT=34;
const usz MAX_ITERATIONS=1000;
const double TOLERANCE=1e-10;
const double MIN_NORM=1e-10;

fn bool finite_value(double x) { return x==x && x<1e300 && x> -1e300; }

fn bool power_iteration(double* matrix, usz n, double* eigenvalue, double* eigenvector) {
    double[MAX_FEATURES] vector=zeroed, previous=zeroed, next=zeroed;
    for(usz i=0;i<n;i++) vector[i]=1.0;
    bool converged=false;
    for(usz iteration=0;iteration<MAX_ITERATIONS;iteration++) {
        for(usz i=0;i<n;i++) previous[i]=vector[i];
        for(usz i=0;i<n;i++) {
            next[i]=0.0;
            for(usz j=0;j<n;j++) {
                double product=matrix[i*n+j]*vector[j];
                if(!finite_value(product)) return false;
                next[i]+=product;
                if(!finite_value(next[i])) return false;
            }
        }
        double norm_squared=0.0;
        for(usz i=0;i<n;i++) {
            double square=next[i]*next[i];
            if(!finite_value(square)) return false;
            norm_squared+=square;
            if(!finite_value(norm_squared)) return false;
        }
        double norm=sqrt(norm_squared);
        if(!finite_value(norm) || norm<=MIN_NORM) return false;
        for(usz i=0;i<n;i++) {
            vector[i]=next[i]/norm;
            if(!finite_value(vector[i])) return false;
        }
        double difference=0.0;
        for(usz i=0;i<n;i++) {
            double d=vector[i]-previous[i]; if(d<0.0)d= -d;
            if(!finite_value(d)) return false;
            if(d>difference) difference=d;
        }
        if(difference<TOLERANCE) { converged=true; break; }
    }
    if(!converged) return false;
    double numerator=0.0;
    for(usz i=0;i<n;i++) {
        double row_sum=0.0;
        for(usz j=0;j<n;j++) {
            double product=matrix[i*n+j]*vector[j];
            if(!finite_value(product)) return false;
            row_sum+=product; if(!finite_value(row_sum)) return false;
        }
        double term=row_sum*vector[i]; if(!finite_value(term)) return false;
        numerator+=term; if(!finite_value(numerator)) return false;
    }
    double denominator=0.0;
    for(usz i=0;i<n;i++) {
        double square=vector[i]*vector[i]; if(!finite_value(square)) return false;
        denominator+=square; if(!finite_value(denominator)) return false;
    }
    if(denominator==0.0) return false;
    *eigenvalue=numerator/denominator;
    if(!finite_value(*eigenvalue)) return false;
    for(usz i=0;i<n;i++) eigenvector[i]=vector[i];
    return true;
}

fn long principal_component_analysis(double* input, usz input_length,
                                     double* output, usz output_capacity) @export("principal_component_analysis") {
    if(input==null || input_length<3 || input_length>MAX_INPUT) return -1L;
    double sv=input[0], fv=input[1], cv=input[2];
    if(!finite_value(sv) || sv<2.0 || sv>8.0 || (double)(long)sv!=sv ||
       !finite_value(fv) || fv<2.0 || fv>4.0 || (double)(long)fv!=fv) return -1L;
    usz samples=(usz)(long)sv, features=(usz)(long)fv;
    if(!finite_value(cv) || cv<1.0 || cv>(double)features || (double)(long)cv!=cv) return -1L;
    usz components=(usz)(long)cv;
    if(input_length!=3+samples*features) return -1L;
    double[MAX_SAMPLES*MAX_FEATURES] rows=zeroed;
    for(usz i=0;i<samples*features;i++) {
        double x=input[3+i]; if(!finite_value(x) || x< -100.0 || x>100.0) return -1L;
        rows[i]=x;
    }
    double[MAX_FEATURES] means=zeroed;
    for(usz row=0;row<samples;row++) for(usz col=0;col<features;col++) {
        means[col]+=rows[row*features+col]; if(!finite_value(means[col])) return -1L;
    }
    for(usz col=0;col<features;col++) {
        means[col]/=(double)samples; if(!finite_value(means[col])) return -1L;
    }
    double[MAX_SAMPLES*MAX_FEATURES] centered=zeroed;
    for(usz row=0;row<samples;row++) for(usz col=0;col<features;col++) {
        centered[row*features+col]=rows[row*features+col]-means[col];
        if(!finite_value(centered[row*features+col])) return -1L;
    }
    double[MAX_FEATURES*MAX_FEATURES] matrix=zeroed;
    for(usz i=0;i<features;i++) for(usz j=i;j<features;j++) {
        double cov=0.0;
        for(usz row=0;row<samples;row++) {
            double product=centered[row*features+i]*centered[row*features+j];
            if(!finite_value(product)) return -1L;
            cov+=product; if(!finite_value(cov)) return -1L;
        }
        cov/=(double)samples; if(!finite_value(cov)) return -1L;
        matrix[i*features+j]=cov; matrix[j*features+i]=cov;
    }
    double[MAX_FEATURES*MAX_FEATURES] vectors=zeroed;
    for(usz component=0;component<components;component++) {
        double eigenvalue=0.0; double[MAX_FEATURES] vector=zeroed;
        if(!power_iteration(&matrix[0],features,&eigenvalue,&vector[0])) return -1L;
        for(usz i=0;i<features;i++) vectors[component*features+i]=vector[i];
        for(usz i=0;i<features;i++) for(usz j=0;j<features;j++) {
            double term=eigenvalue*vector[i]*vector[j]; if(!finite_value(term)) return -1L;
            matrix[i*features+j]-=term; if(!finite_value(matrix[i*features+j])) return -1L;
        }
    }
    double[MAX_OUTPUT] staged=zeroed;
    staged[0]=(double)samples; staged[1]=(double)components; usz pos=2;
    for(usz row=0;row<samples;row++) for(usz component=0;component<components;component++) {
        double score=0.0;
        for(usz feature=0;feature<features;feature++) {
            double product=vectors[component*features+feature]*centered[row*features+feature];
            if(!finite_value(product)) return -1L;
            score+=product; if(!finite_value(score)) return -1L;
        }
        staged[pos++]=score;
    }
    if(output==null || output_capacity<pos) return -2L;
    for(usz i=0;i<pos;i++) output[i]=staged[i];
    return (long)pos;
}
