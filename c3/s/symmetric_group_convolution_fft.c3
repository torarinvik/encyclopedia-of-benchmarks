// Uncompiled C3 symmetric-group convolution ABI draft.
module symmetric_group_convolution_fft;
extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

const long SG_MOD = 998244353;
const int SG_SHAPES = 30;
const int SG_BASIS = 603; // dim^2 <= 9!, hence dim <= 602.
const int[10] SG_FACTORIAL = {1,1,2,6,24,120,720,5040,40320,362880};

struct SGTableau { int[9] cells; }
struct SGColumn { long diagonal; long coefficient; int partner; }
struct SGEmbedding { int child; int offset; int width; }
struct SGRep {
    int[9] shape;
    SGTableau* basis;
    int count;
    SGColumn* adjacent;
    SGEmbedding[9] restrictions;
    int restriction_count;
}
struct SGLevel { SGRep[30] items; int count; }
struct SGPlan { SGLevel[10] levels; }

fn long sg_power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result*base % SG_MOD;
        base = base*base % SG_MOD;
        exponent >>= 1;
    }
    return result;
}

fn int sg_shape_cmp(int[9]* a, int[9]* b) {
    for (int i = 0; i < 9; i++) {
        if ((*a)[i] < (*b)[i]) return -1;
        if ((*a)[i] > (*b)[i]) return 1;
    }
    return 0;
}

fn int sg_tableau_cmp(SGTableau* a, SGTableau* b, int n) {
    for (int i = n-1; i >= 0; i--) {
        if (a.cells[i] < b.cells[i]) return -1;
        if (a.cells[i] > b.cells[i]) return 1;
    }
    return 0;
}

fn void sg_free_plan(SGPlan* plan) {
    for (int n = 1; n <= 9; n++) {
        SGLevel* level = &plan.levels[n];
        for (int i = 0; i < level.count; i++) {
            free(level.items[i].basis);
            free(level.items[i].adjacent);
        }
        level.count = 0;
    }
}

// Error status is -3 for allocation failure, -4 for an invariant failure.
fn void sg_enumerate(SGLevel* level, int degree, int next, int[9]* shape,
                     SGTableau* tableau, int* status) {
    if (*status != 0) return;
    if (next == degree) {
        int index = 0;
        while (index < level.count && sg_shape_cmp(&level.items[index].shape, shape) != 0) index++;
        if (index == level.count) {
            if (index == SG_SHAPES) { *status = -4; return; }
            SGRep* fresh = &level.items[index];
            fresh.shape = *shape;
            fresh.basis = (SGTableau*)calloc(SG_BASIS, sizeof(SGTableau));
            if (fresh.basis == null) { *status = -3; return; }
            level.count++;
        }
        SGRep* rep = &level.items[index];
        if (rep.count == SG_BASIS) { *status = -4; return; }
        rep.basis[rep.count++] = *tableau;
        return;
    }
    for (int row = 0; row < degree; row++) {
        if (row > 0 && (*shape)[row] >= (*shape)[row-1]) continue;
        int column = (*shape)[row];
        tableau.cells[next] = row*9+column;
        (*shape)[row]++;
        sg_enumerate(level,degree,next+1,shape,tableau,status);
        (*shape)[row]--;
        if (*status != 0 || column == 0) return;
    }
}

fn void sg_prepare_level(SGLevel* level, int n, int* status) {
    int[9] shape = {};
    SGTableau tableau = {};
    sg_enumerate(level,n,0,&shape,&tableau,status);
    if (*status != 0) return;
    for (int i = 1; i < level.count; i++) {
        int j = i;
        while (j > 0 && sg_shape_cmp(&level.items[j-1].shape,&level.items[j].shape) > 0) {
            SGRep temp = level.items[j-1]; level.items[j-1] = level.items[j]; level.items[j] = temp;
            j--;
        }
    }
    for (int r = 0; r < level.count; r++) {
        SGRep* rep = &level.items[r];
        for (int i = 1; i < rep.count; i++) {
            int j = i;
            while (j > 0 && sg_tableau_cmp(&rep.basis[j-1],&rep.basis[j],n) > 0) {
                SGTableau temp = rep.basis[j-1]; rep.basis[j-1] = rep.basis[j]; rep.basis[j] = temp;
                j--;
            }
        }
        if (n > 1) {
            rep.adjacent = (SGColumn*)calloc((usz)((n-1)*rep.count),sizeof(SGColumn));
            if (rep.adjacent == null) { *status = -3; return; }
        }
        for (int label = 0; label < n-1; label++) for (int i = 0; i < rep.count; i++) {
            int first = rep.basis[i].cells[label], second = rep.basis[i].cells[label+1];
            int distance = second%9-second/9-first%9+first/9;
            if (distance == 0) { *status = -4; return; }
            long diagonal = sg_power((distance+SG_MOD)%SG_MOD,SG_MOD-2);
            SGColumn column = {diagonal, 0, -1};
            if (distance != 1 && distance != -1) {
                SGTableau exchanged = rep.basis[i];
                int temp = exchanged.cells[label]; exchanged.cells[label] = exchanged.cells[label+1]; exchanged.cells[label+1] = temp;
                int lo = 0, hi = rep.count;
                while (lo < hi) {
                    int mid = lo+(hi-lo)/2;
                    if (sg_tableau_cmp(&rep.basis[mid],&exchanged,n) < 0) lo = mid+1;
                    else hi = mid;
                }
                if (lo == rep.count || sg_tableau_cmp(&rep.basis[lo],&exchanged,n) != 0) { *status = -4; return; }
                column.partner = lo;
                column.coefficient = distance > 0 ? 1 : (1-diagonal*diagonal%SG_MOD+SG_MOD)%SG_MOD;
            }
            rep.adjacent[label*rep.count+i] = column;
        }
    }
}

fn void sg_make_plan(SGPlan* plan, int degree, int* status) {
    if (degree < 1 || degree > 9) { *status = -4; return; }
    for (int n = 1; n <= degree; n++) {
        sg_prepare_level(&plan.levels[n],n,status);
        if (*status != 0) return;
        if (n == 1) continue;
        SGLevel* children = &plan.levels[n-1];
        SGLevel* parents = &plan.levels[n];
        for (int i = 0; i < parents.count; i++) {
            SGRep* parent = &parents.items[i];
            int start = 0;
            while (start < parent.count) {
                int corner = parent.basis[start].cells[n-1];
                int end = start+1;
                while (end < parent.count && parent.basis[end].cells[n-1] == corner) end++;
                int[9] child_shape = parent.shape;
                int row = corner/9;
                if (row >= 9 || child_shape[row] == 0) { *status = -4; return; }
                child_shape[row]--;
                int child = 0;
                while (child < children.count && sg_shape_cmp(&children.items[child].shape,&child_shape) != 0) child++;
                if (child == children.count || children.items[child].count != end-start || parent.restriction_count == 9) { *status = -4; return; }
                for (int k = 0; k < end-start; k++) for (int label = 0; label < n-1; label++)
                    if (parent.basis[start+k].cells[label] != children.items[child].basis[k].cells[label]) { *status = -4; return; }
                parent.restrictions[parent.restriction_count++] = {child,start,end-start};
                start = end;
            }
        }
    }
}

struct SGBlocks { long*[30] items; int count; }

fn void sg_free_blocks(SGBlocks* blocks) {
    for (int i = 0; i < blocks.count; i++) free(blocks.items[i]);
    blocks.count = 0;
}

fn void sg_allocate_blocks(SGLevel* level, SGBlocks* blocks, int* status) {
    if (*status != 0) return;
    for (int i = 0; i < level.count; i++) {
        int d = level.items[i].count;
        if (d <= 0 || d > SG_BASIS) { *status = -4; return; }
        blocks.items[i] = (long*)calloc((usz)(d*d),sizeof(long));
        if (blocks.items[i] == null) { *status = -3; return; }
        blocks.count++;
    }
}

fn int sg_rank(int[9]* permutation, int n) {
    int rank = 0;
    for (int i = 0; i < n; i++) {
        int smaller = 0;
        for (int j = i+1; j < n; j++) if ((*permutation)[j] < (*permutation)[i]) smaller++;
        rank += smaller*SG_FACTORIAL[n-1-i];
    }
    return rank;
}

fn bool sg_next_permutation(int[9]* values, int n) {
    if (n < 2) return false;
    int pivot = n-1;
    while (pivot > 0 && (*values)[pivot-1] >= (*values)[pivot]) pivot--;
    if (pivot == 0) return false;
    int successor = n-1;
    while ((*values)[successor] <= (*values)[pivot-1]) successor--;
    int temp = (*values)[pivot-1]; (*values)[pivot-1] = (*values)[successor]; (*values)[successor] = temp;
    int left = pivot, right = n-1;
    while (left < right) {
        temp = (*values)[left]; (*values)[left++] = (*values)[right]; (*values)[right--] = temp;
    }
    return true;
}

fn void sg_apply_generator(SGRep* rep, int label, long* source, long* destination,
                           bool transpose, int* status) {
    if (*status != 0) return;
    int d = rep.count;
    for (int i = 0; i < d*d; i++) destination[i] = 0;
    for (int row = 0; row < d; row++) {
        SGColumn entry = rep.adjacent[label*d+row];
        if (entry.partner >= d) { *status = -4; return; }
        for (int col = 0; col < d; col++) {
            if (transpose) {
                long value = entry.diagonal*source[row*d+col]%SG_MOD;
                if (entry.partner >= 0) value = (value+entry.coefficient*source[entry.partner*d+col])%SG_MOD;
                destination[row*d+col] = value;
            } else {
                long value = source[row*d+col];
                int index = row*d+col;
                destination[index] = (destination[index]+entry.diagonal*value)%SG_MOD;
                if (entry.partner >= 0) {
                    int partner = entry.partner*d+col;
                    destination[partner] = (destination[partner]+entry.coefficient*value)%SG_MOD;
                }
            }
        }
    }
}

// The caller owns any blocks produced, including on an error return.
fn void sg_forward(SGPlan* plan, int n, long* input, SGBlocks* output, int* status) {
    if (*status != 0) return;
    if (n < 1 || n > 9) { *status = -4; return; }
    SGLevel* level = &plan.levels[n];
    sg_allocate_blocks(level,output,status);
    if (*status != 0) return;
    if (n == 1) { output.items[0][0] = input[0]; return; }
    long* restricted = (long*)calloc((usz)SG_FACTORIAL[n-1],sizeof(long));
    if (restricted == null) { *status = -3; return; }
    for (int image = 0; image < n && *status == 0; image++) {
        int[9] h = {};
        for (int i = 0; i < n-1; i++) h[i] = i;
        int index = 0;
        do {
            int[9] permutation = h;
            permutation[n-1] = n-1;
            for (int i = 0; i < n; i++) {
                if (permutation[i] == image) permutation[i] = n-1;
                else if (permutation[i] == n-1) permutation[i] = image;
            }
            if (index >= SG_FACTORIAL[n-1]) { *status = -4; break; }
            restricted[index++] = input[sg_rank(&permutation,n)];
        } while (sg_next_permutation(&h,n-1));
        if (*status == 0 && index != SG_FACTORIAL[n-1]) *status = -4;
        SGBlocks child = {};
        sg_forward(plan,n-1,restricted,&child,status);
        for (int shape = 0; shape < level.count && *status == 0; shape++) {
            SGRep* rep = &level.items[shape];
            int d = rep.count;
            long* current = (long*)calloc((usz)(d*d),sizeof(long));
            long* next = (long*)calloc((usz)(d*d),sizeof(long));
            if (current == null || next == null) *status = -3;
            for (int k = 0; k < rep.restriction_count && *status == 0; k++) {
                SGEmbedding entry = rep.restrictions[k];
                if (entry.child < 0 || entry.child >= child.count || entry.offset < 0 ||
                    entry.width < 0 || entry.offset+entry.width > d ||
                    plan.levels[n-1].items[entry.child].count != entry.width) { *status = -4; break; }
                for (int row = 0; row < entry.width; row++) for (int col = 0; col < entry.width; col++)
                    current[(entry.offset+row)*d+entry.offset+col] = child.items[entry.child][row*entry.width+col];
            }
            for (int g = image; g < n-1 && *status == 0; g++) {
                sg_apply_generator(rep,g,current,next,false,status);
                long* swap = current; current = next; next = swap;
            }
            for (int g = n-3; g >= image && *status == 0; g--) {
                sg_apply_generator(rep,g,current,next,false,status);
                long* swap = current; current = next; next = swap;
            }
            if (*status == 0) for (int i = 0; i < d*d; i++)
                output.items[shape][i] = (output.items[shape][i]+current[i])%SG_MOD;
            free(current); free(next);
        }
        sg_free_blocks(&child);
    }
    free(restricted);
}

fn void sg_invariant_diagonal(SGRep* rep, int n, long* weights, int* status) {
    if (*status != 0) return;
    int d = rep.count;
    int* queue = (int*)calloc((usz)d,sizeof(int));
    if (queue == null) { *status = -3; return; }
    for (int i = 0; i < d; i++) weights[i] = -1;
    for (int start = 0; start < d && *status == 0; start++) {
        if (weights[start] != -1) continue;
        int head = 0, tail = 1;
        weights[start] = 1; queue[0] = start;
        while (head < tail && *status == 0) {
            int source = queue[head++];
            for (int label = 0; label < n-1; label++) {
                SGColumn edge = rep.adjacent[label*d+source];
                if (edge.partner < 0) continue;
                if (edge.partner >= d) { *status = -4; break; }
                SGColumn back = rep.adjacent[label*d+edge.partner];
                if (back.partner != source || edge.coefficient == 0 || back.coefficient == 0) { *status = -4; break; }
                long candidate = weights[source]*back.coefficient%SG_MOD;
                candidate = candidate*sg_power(edge.coefficient,SG_MOD-2)%SG_MOD;
                if (weights[edge.partner] == -1) {
                    if (tail >= d) { *status = -4; break; }
                    weights[edge.partner] = candidate; queue[tail++] = edge.partner;
                } else if (weights[edge.partner] != candidate) { *status = -4; break; }
            }
        }
    }
    free(queue);
}

// Caller frees the result, including on error if it is non-null.
fn long* sg_transpose_forward(SGPlan* plan, int n, SGBlocks* gradients, int* status) {
    if (*status != 0) return null;
    if (n < 1 || n > 9 || gradients.count != plan.levels[n].count) { *status = -4; return null; }
    long* output = (long*)calloc((usz)SG_FACTORIAL[n],sizeof(long));
    if (output == null) { *status = -3; return null; }
    if (n == 1) { output[0] = gradients.items[0][0]; return output; }
    SGLevel* level = &plan.levels[n];
    for (int image = 0; image < n && *status == 0; image++) {
        SGBlocks child = {};
        sg_allocate_blocks(&plan.levels[n-1],&child,status);
        for (int shape = 0; shape < level.count && *status == 0; shape++) {
            SGRep* rep = &level.items[shape];
            int d = rep.count;
            long* current = (long*)calloc((usz)(d*d),sizeof(long));
            long* next = (long*)calloc((usz)(d*d),sizeof(long));
            if (current == null || next == null) *status = -3;
            if (*status == 0) for (int i = 0; i < d*d; i++) current[i] = gradients.items[shape][i];
            for (int g = image; g < n-1 && *status == 0; g++) {
                sg_apply_generator(rep,g,current,next,true,status);
                long* swap = current; current = next; next = swap;
            }
            for (int g = n-3; g >= image && *status == 0; g--) {
                sg_apply_generator(rep,g,current,next,true,status);
                long* swap = current; current = next; next = swap;
            }
            for (int k = 0; k < rep.restriction_count && *status == 0; k++) {
                SGEmbedding entry = rep.restrictions[k];
                if (entry.child < 0 || entry.child >= child.count || entry.offset < 0 ||
                    entry.width < 0 || entry.offset+entry.width > d ||
                    plan.levels[n-1].items[entry.child].count != entry.width) { *status = -4; break; }
                for (int row = 0; row < entry.width; row++) for (int col = 0; col < entry.width; col++) {
                    int target = row*entry.width+col;
                    child.items[entry.child][target] = (child.items[entry.child][target] +
                        current[(entry.offset+row)*d+entry.offset+col])%SG_MOD;
                }
            }
            free(current); free(next);
        }
        long* restricted = sg_transpose_forward(plan,n-1,&child,status);
        sg_free_blocks(&child);
        if (*status == 0) {
            int[9] h = {};
            for (int i = 0; i < n-1; i++) h[i] = i;
            int index = 0;
            do {
                int[9] permutation = h;
                permutation[n-1] = n-1;
                for (int i = 0; i < n; i++) {
                    if (permutation[i] == image) permutation[i] = n-1;
                    else if (permutation[i] == n-1) permutation[i] = image;
                }
                if (index >= SG_FACTORIAL[n-1]) { *status = -4; break; }
                output[sg_rank(&permutation,n)] = restricted[index++];
            } while (sg_next_permutation(&h,n-1));
            if (*status == 0 && index != SG_FACTORIAL[n-1]) *status = -4;
        }
        free(restricted);
    }
    return output;
}

fn long* sg_inverse(SGPlan* plan, int n, SGBlocks* blocks, int* status) {
    if (*status != 0) return null;
    if (n < 1 || n > 9 || blocks.count != plan.levels[n].count) { *status = -4; return null; }
    SGBlocks weighted = {};
    sg_allocate_blocks(&plan.levels[n],&weighted,status);
    long inverse_order = sg_power(SG_FACTORIAL[n],SG_MOD-2);
    for (int shape = 0; shape < plan.levels[n].count && *status == 0; shape++) {
        SGRep* rep = &plan.levels[n].items[shape];
        int d = rep.count;
        long* diagonal = (long*)calloc((usz)d,sizeof(long));
        long* inverse_diagonal = (long*)calloc((usz)d,sizeof(long));
        if (diagonal == null || inverse_diagonal == null) *status = -3;
        if (*status == 0) sg_invariant_diagonal(rep,n,diagonal,status);
        if (*status == 0) {
            for (int i = 0; i < d; i++) inverse_diagonal[i] = sg_power(diagonal[i],SG_MOD-2);
            for (int row = 0; row < d; row++) for (int col = 0; col < d; col++) {
                long value = blocks.items[shape][row*d+col]*d%SG_MOD;
                value = value*inverse_order%SG_MOD;
                value = value*diagonal[row]%SG_MOD;
                weighted.items[shape][row*d+col] = value*inverse_diagonal[col]%SG_MOD;
            }
        }
        free(diagonal); free(inverse_diagonal);
    }
    long* output = sg_transpose_forward(plan,n,&weighted,status);
    sg_free_blocks(&weighted);
    return output;
}

fn long symmetric_group_convolution_fft(long* input, usz length, uchar* output, usz capacity)
        @export("symmetric_group_convolution_fft") {
    if (input == null || length < 1 || length > 725762 || input[0] < 1 || input[0] > 9) return -1;
    int n = (int)input[0], count = SG_FACTORIAL[n];
    if (length != (usz)(1+2*count)) return -1;
    for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] >= SG_MOD) return -1;
    if (output == null || capacity < (usz)(4*count)) return -2;

    SGPlan* plan = (SGPlan*)calloc(1,sizeof(SGPlan));
    if (plan == null) return -3;
    int status = 0;
    SGBlocks left = {}, right = {}, product = {};
    sg_make_plan(plan,n,&status);
    sg_forward(plan,n,input+1,&left,&status);
    sg_forward(plan,n,input+1+count,&right,&status);
    sg_allocate_blocks(&plan.levels[n],&product,&status);
    for (int shape = 0; shape < plan.levels[n].count && status == 0; shape++) {
        int d = plan.levels[n].items[shape].count;
        for (int row = 0; row < d; row++) for (int inner = 0; inner < d; inner++) for (int col = 0; col < d; col++) {
            int index = row*d+col;
            product.items[shape][index] = (product.items[shape][index]+
                left.items[shape][row*d+inner]*right.items[shape][inner*d+col])%SG_MOD;
        }
    }
    long* result = sg_inverse(plan,n,&product,&status);
    if (status == 0) {
        for (int i = 0; i < count; i++) {
            uint value = (uint)result[i];
            for (int byte = 0; byte < 4; byte++) output[4*i+byte] = (uchar)(value >> (8*byte));
        }
    }
    free(result);
    sg_free_blocks(&product); sg_free_blocks(&right); sg_free_blocks(&left);
    sg_free_plan(plan); free(plan);
    return status == 0 ? (long)(4*count) : (long)status;
}
