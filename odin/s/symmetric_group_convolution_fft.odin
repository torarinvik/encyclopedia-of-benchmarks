// Uncompiled Odin subgroup-transform ABI draft. Allocation failures may not
// yet produce the proposed -3 return code.
package symmetric_group_convolution_fft
import "core:c"
import "base:runtime"

SG_PRIME :: i64(998244353)
SG_FACTORIAL :: [10]int{1,1,2,6,24,120,720,5040,40320,362880}
// The sum of squared irreducible dimensions is n!, so for n <= 9 each
// dimension is at most floor(sqrt(9!)) = 602. There are at most 30 shapes.
SG_BASIS_LIMIT :: 603
SG_SHAPE_LIMIT :: 30
SG_Shape :: [9]u8
SG_Tableau :: [9]u8
SG_Column :: struct { diagonal, coefficient: i64, partner: int }
SG_Embedding :: struct { child, offset, width: int }
SG_Representation :: struct {
    shape: SG_Shape,
    basis: []SG_Tableau,
    count: int,
    generators: []SG_Column,
    restrictions: [9]SG_Embedding,
    restriction_count: int,
}
SG_Level :: struct { items: [SG_SHAPE_LIMIT]SG_Representation, count: int }
SG_Plan :: struct { levels: [10]SG_Level }

sg_power :: proc(base_value, exponent_value: i64) -> i64 {
    base, exponent, value := base_value, exponent_value, i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 { value = value*base % SG_PRIME }
        base = base*base % SG_PRIME
        exponent >>= 1
    }
    return value
}

sg_free_plan :: proc(plan: ^SG_Plan) {
    for degree := 1; degree <= 9; degree += 1 {
        level := &plan.levels[degree]
        for i := 0; i < level.count; i += 1 {
            delete(level.items[i].basis)
            delete(level.items[i].generators)
        }
        level.count = 0
    }
}

sg_shape_compare :: proc(a, b: SG_Shape) -> int {
    for i := 0; i < 9; i += 1 {
        if a[i] < b[i] { return -1 }
        if a[i] > b[i] { return 1 }
    }
    return 0
}

sg_tableau_compare :: proc(a, b: SG_Tableau, n: int) -> int {
    for i := n-1; i >= 0; i -= 1 {
        if a[i] < b[i] { return -1 }
        if a[i] > b[i] { return 1 }
    }
    return 0
}

sg_enumerate :: proc(level: ^SG_Level, degree, next: int,
                     shape: ^SG_Shape, tableau: ^SG_Tableau) -> bool {
    if next == degree {
        index := 0
        for index < level.count && sg_shape_compare(level.items[index].shape, shape^) != 0 { index += 1 }
        if index == level.count {
            if index == SG_SHAPE_LIMIT { return false }
            level.items[index].shape = shape^
            level.items[index].basis = make([]SG_Tableau, SG_BASIS_LIMIT)
            level.count += 1
        }
        rep := &level.items[index]
        if rep.count == SG_BASIS_LIMIT { return false }
        rep.basis[rep.count] = tableau^
        rep.count += 1
        return true
    }
    for row := 0; row < degree; row += 1 {
        if row > 0 && shape^[row] >= shape^[row-1] { continue }
        column := shape^[row]
        tableau^[next] = u8(row*9 + int(column))
        shape^[row] += 1
        ok := sg_enumerate(level,degree,next+1,shape,tableau)
        shape^[row] -= 1
        if !ok { return false }
        if column == 0 { break }
    }
    return true
}

sg_prepare_level :: proc(level: ^SG_Level, n: int) -> bool {
    shape: SG_Shape
    tableau: SG_Tableau
    if !sg_enumerate(level,n,0,&shape,&tableau) { return false }
    for i := 1; i < level.count; i += 1 {
        for j := i; j > 0 && sg_shape_compare(level.items[j-1].shape,level.items[j].shape) > 0; j -= 1 {
            level.items[j-1], level.items[j] = level.items[j], level.items[j-1]
        }
    }
    for r := 0; r < level.count; r += 1 {
        rep := &level.items[r]
        for i := 1; i < rep.count; i += 1 {
            for j := i; j > 0 && sg_tableau_compare(rep.basis[j-1],rep.basis[j],n) > 0; j -= 1 {
                rep.basis[j-1], rep.basis[j] = rep.basis[j], rep.basis[j-1]
            }
        }
        rep.generators = make([]SG_Column,(n-1)*rep.count)
        for label := 0; label+1 < n; label += 1 {
            for i := 0; i < rep.count; i += 1 {
                first, second := int(rep.basis[i][label]), int(rep.basis[i][label+1])
                distance := second%9 - second/9 - first%9 + first/9
                if distance == 0 { return false }
                diagonal := sg_power((i64(distance)+SG_PRIME)%SG_PRIME,SG_PRIME-2)
                column := SG_Column{diagonal = diagonal, partner = -1}
                if distance != 1 && distance != -1 {
                    exchanged := rep.basis[i]
                    exchanged[label], exchanged[label+1] = exchanged[label+1], exchanged[label]
                    lo, hi := 0, rep.count
                    for lo < hi {
                        mid := lo+(hi-lo)/2
                        if sg_tableau_compare(rep.basis[mid],exchanged,n) < 0 { lo = mid+1 } else { hi = mid }
                    }
                    if lo == rep.count || sg_tableau_compare(rep.basis[lo],exchanged,n) != 0 { return false }
                    column.partner = lo
                    column.coefficient = 1
                    if distance < 0 { column.coefficient = (1-diagonal*diagonal%SG_PRIME+SG_PRIME)%SG_PRIME }
                }
                rep.generators[label*rep.count+i] = column
            }
        }
    }
    return true
}

sg_make_plan :: proc(plan: ^SG_Plan, degree: int) -> bool {
    if degree < 1 || degree > 9 { return false }
    for n := 1; n <= degree; n += 1 {
        if !sg_prepare_level(&plan.levels[n],n) { return false }
        if n == 1 { continue }
        children := &plan.levels[n-1]
        parents := &plan.levels[n]
        for i := 0; i < parents.count; i += 1 {
            parent := &parents.items[i]
            for start := 0; start < parent.count; {
                corner := int(parent.basis[start][n-1])
                end := start+1
                for end < parent.count && int(parent.basis[end][n-1]) == corner { end += 1 }
                child_shape := parent.shape
                row := corner/9
                if row >= 9 || child_shape[row] == 0 { return false }
                child_shape[row] -= 1
                child := 0
                for child < children.count && sg_shape_compare(children.items[child].shape,child_shape) != 0 { child += 1 }
                if child == children.count || children.items[child].count != end-start || parent.restriction_count == 9 { return false }
                for k := 0; k < end-start; k += 1 {
                    for label := 0; label < n-1; label += 1 {
                        if parent.basis[start+k][label] != children.items[child].basis[k][label] { return false }
                    }
                }
                parent.restrictions[parent.restriction_count] = SG_Embedding{child, start, end-start}
                parent.restriction_count += 1
                start = end
            }
        }
    }
    return true
}

SG_Blocks :: struct { items: [SG_SHAPE_LIMIT][]i64, count: int }

sg_free_blocks :: proc(blocks: ^SG_Blocks) {
    for i := 0; i < blocks.count; i += 1 { delete(blocks.items[i]) }
    blocks.count = 0
}

sg_allocate_blocks :: proc(level: ^SG_Level, blocks: ^SG_Blocks) {
    for i := 0; i < level.count; i += 1 {
        dimension := level.items[i].count
        blocks.items[i] = make([]i64, dimension*dimension)
        blocks.count += 1
    }
}

sg_permutation_rank :: proc(permutation: ^[9]int, n: int) -> int {
    rank := 0
    for i := 0; i < n; i += 1 {
        smaller := 0
        for j := i+1; j < n; j += 1 { if permutation^[j] < permutation^[i] { smaller += 1 } }
        rank += smaller*SG_FACTORIAL[n-1-i]
    }
    return rank
}

sg_next_permutation :: proc(values: ^[9]int, n: int) -> bool {
    if n < 2 { return false }
    pivot := n-1
    for pivot > 0 && values^[pivot-1] >= values^[pivot] { pivot -= 1 }
    if pivot == 0 { return false }
    successor := n-1
    for values^[successor] <= values^[pivot-1] { successor -= 1 }
    values^[pivot-1], values^[successor] = values^[successor], values^[pivot-1]
    left, right := pivot, n-1
    for left < right {
        values^[left], values^[right] = values^[right], values^[left]
        left += 1; right -= 1
    }
    return true
}

sg_apply_generator :: proc(rep: ^SG_Representation, label: int,
                           source, destination: []i64, transpose: bool) -> bool {
    d := rep.count
    if len(source) != d*d || len(destination) != d*d { return false }
    for i := 0; i < len(destination); i += 1 { destination[i] = 0 }
    for row := 0; row < d; row += 1 {
        entry := rep.generators[label*d+row]
        if entry.partner >= d { return false }
        for col := 0; col < d; col += 1 {
            if transpose {
                value := entry.diagonal*source[row*d+col]%SG_PRIME
                if entry.partner >= 0 { value = (value+entry.coefficient*source[entry.partner*d+col])%SG_PRIME }
                destination[row*d+col] = value
            } else {
                value := source[row*d+col]
                index := row*d+col
                destination[index] = (destination[index]+entry.diagonal*value)%SG_PRIME
                if entry.partner >= 0 {
                    partner := entry.partner*d+col
                    destination[partner] = (destination[partner]+entry.coefficient*value)%SG_PRIME
                }
            }
        }
    }
    return true
}

// The caller owns the returned blocks even on a false return.
sg_forward :: proc(plan: ^SG_Plan, n: int, input: []i64, output: ^SG_Blocks) -> bool {
    if n < 1 || n > 9 || len(input) != SG_FACTORIAL[n] { return false }
    level := &plan.levels[n]
    sg_allocate_blocks(level,output)
    if n == 1 { output.items[0][0] = input[0]; return true }
    restricted := make([]i64,SG_FACTORIAL[n-1])
    defer delete(restricted)
    for image := 0; image < n; image += 1 {
        h: [9]int
        for i := 0; i < n-1; i += 1 { h[i] = i }
        index := 0
        for {
            permutation := h
            permutation[n-1] = n-1
            for i := 0; i < n; i += 1 {
                if permutation[i] == image { permutation[i] = n-1 } else if permutation[i] == n-1 { permutation[i] = image }
            }
            if index >= len(restricted) { return false }
            restricted[index] = input[sg_permutation_rank(&permutation,n)]
            index += 1
            if !sg_next_permutation(&h,n-1) { break }
        }
        if index != len(restricted) { return false }
        child: SG_Blocks
        defer sg_free_blocks(&child)
        if !sg_forward(plan,n-1,restricted,&child) { return false }
        for shape := 0; shape < level.count; shape += 1 {
            rep := &level.items[shape]
            d := rep.count
            current := make([]i64,d*d)
            next := make([]i64,d*d)
            defer delete(current)
            defer delete(next)
            for k := 0; k < rep.restriction_count; k += 1 {
                entry := rep.restrictions[k]
                if entry.child < 0 || entry.child >= child.count || entry.offset < 0 ||
                    entry.width < 0 || entry.offset+entry.width > d || len(child.items[entry.child]) != entry.width*entry.width { return false }
                for row := 0; row < entry.width; row += 1 {
                    for col := 0; col < entry.width; col += 1 {
                        current[(entry.offset+row)*d+entry.offset+col] = child.items[entry.child][row*entry.width+col]
                    }
                }
            }
            for generator := image; generator < n-1; generator += 1 {
                if !sg_apply_generator(rep,generator,current,next,false) { return false }
                current, next = next, current
            }
            for generator := n-3; generator >= image; generator -= 1 {
                if !sg_apply_generator(rep,generator,current,next,false) { return false }
                current, next = next, current
            }
            for i := 0; i < d*d; i += 1 { output.items[shape][i] = (output.items[shape][i]+current[i])%SG_PRIME }
        }
    }
    return true
}

sg_invariant_diagonal :: proc(rep: ^SG_Representation, n: int, weights: []i64) -> bool {
    d := rep.count
    if len(weights) != d { return false }
    queue := make([]int,d)
    defer delete(queue)
    for i := 0; i < d; i += 1 { weights[i] = -1 }
    for start := 0; start < d; start += 1 {
        if weights[start] != -1 { continue }
        head, tail := 0, 1
        weights[start] = 1; queue[0] = start
        for head < tail {
            source := queue[head]; head += 1
            for label := 0; label < n-1; label += 1 {
                edge := rep.generators[label*d+source]
                if edge.partner < 0 { continue }
                if edge.partner >= d { return false }
                back := rep.generators[label*d+edge.partner]
                if back.partner != source || edge.coefficient == 0 || back.coefficient == 0 { return false }
                candidate := weights[source]*back.coefficient%SG_PRIME
                candidate = candidate*sg_power(edge.coefficient,SG_PRIME-2)%SG_PRIME
                if weights[edge.partner] == -1 {
                    if tail >= d { return false }
                    weights[edge.partner] = candidate
                    queue[tail] = edge.partner; tail += 1
                } else if weights[edge.partner] != candidate { return false }
            }
        }
    }
    return true
}

// The caller owns output, including when this procedure returns false.
sg_transpose_forward :: proc(plan: ^SG_Plan, n: int, gradients: ^SG_Blocks,
                             output: ^[]i64) -> bool {
    if n < 1 || n > 9 || gradients.count != plan.levels[n].count { return false }
    output^ = make([]i64,SG_FACTORIAL[n])
    if n == 1 {
        if len(gradients.items[0]) != 1 { return false }
        output^[0] = gradients.items[0][0]
        return true
    }
    level := &plan.levels[n]
    for image := 0; image < n; image += 1 {
        child: SG_Blocks
        sg_allocate_blocks(&plan.levels[n-1],&child)
        defer sg_free_blocks(&child)
        for shape := 0; shape < level.count; shape += 1 {
            rep := &level.items[shape]
            d := rep.count
            if len(gradients.items[shape]) != d*d { return false }
            current := make([]i64,d*d)
            next := make([]i64,d*d)
            defer delete(current)
            defer delete(next)
            for i := 0; i < d*d; i += 1 { current[i] = gradients.items[shape][i] }
            for generator := image; generator < n-1; generator += 1 {
                if !sg_apply_generator(rep,generator,current,next,true) { return false }
                current, next = next, current
            }
            for generator := n-3; generator >= image; generator -= 1 {
                if !sg_apply_generator(rep,generator,current,next,true) { return false }
                current, next = next, current
            }
            for k := 0; k < rep.restriction_count; k += 1 {
                entry := rep.restrictions[k]
                if entry.child < 0 || entry.child >= child.count || entry.offset < 0 ||
                    entry.width < 0 || entry.offset+entry.width > d || len(child.items[entry.child]) != entry.width*entry.width { return false }
                for row := 0; row < entry.width; row += 1 {
                    for col := 0; col < entry.width; col += 1 {
                        index := row*entry.width+col
                        child.items[entry.child][index] = (child.items[entry.child][index] +
                            current[(entry.offset+row)*d+entry.offset+col])%SG_PRIME
                    }
                }
            }
        }
        restricted: []i64
        if !sg_transpose_forward(plan,n-1,&child,&restricted) {
            delete(restricted)
            return false
        }
        defer delete(restricted)
        h: [9]int
        for i := 0; i < n-1; i += 1 { h[i] = i }
        index := 0
        for {
            permutation := h
            permutation[n-1] = n-1
            for i := 0; i < n; i += 1 {
                if permutation[i] == image { permutation[i] = n-1 } else if permutation[i] == n-1 { permutation[i] = image }
            }
            if index >= len(restricted) { return false }
            output^[sg_permutation_rank(&permutation,n)] = restricted[index]
            index += 1
            if !sg_next_permutation(&h,n-1) { break }
        }
        if index != len(restricted) { return false }
    }
    return true
}

sg_inverse :: proc(plan: ^SG_Plan, n: int, blocks: ^SG_Blocks, output: ^[]i64) -> bool {
    if n < 1 || n > 9 || blocks.count != plan.levels[n].count { return false }
    weighted: SG_Blocks
    sg_allocate_blocks(&plan.levels[n],&weighted)
    defer sg_free_blocks(&weighted)
    inverse_order := sg_power(i64(SG_FACTORIAL[n]),SG_PRIME-2)
    for shape := 0; shape < plan.levels[n].count; shape += 1 {
        rep := &plan.levels[n].items[shape]
        d := rep.count
        if len(blocks.items[shape]) != d*d { return false }
        diagonal := make([]i64,d)
        inverse_diagonal := make([]i64,d)
        defer delete(diagonal)
        defer delete(inverse_diagonal)
        if !sg_invariant_diagonal(rep,n,diagonal) { return false }
        for i := 0; i < d; i += 1 { inverse_diagonal[i] = sg_power(diagonal[i],SG_PRIME-2) }
        for row := 0; row < d; row += 1 {
            for col := 0; col < d; col += 1 {
                value := blocks.items[shape][row*d+col]*i64(d)%SG_PRIME
                value = value*inverse_order%SG_PRIME
                value = value*diagonal[row]%SG_PRIME
                weighted.items[shape][row*d+col] = value*inverse_diagonal[col]%SG_PRIME
            }
        }
    }
    return sg_transpose_forward(plan,n,&weighted,output)
}

@(export)
symmetric_group_convolution_fft :: proc "c" (input: [^]i64, length: c.size_t,
                                             output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 725762 { return -1 }
    if input[0] < 1 || input[0] > 9 { return -1 }
    n := int(input[0])
    count := SG_FACTORIAL[n]
    if length != c.size_t(1+2*count) { return -1 }
    for i := 1; i < int(length); i += 1 {
        if input[i] < 0 || input[i] >= SG_PRIME { return -1 }
    }
    if output == nil || capacity < c.size_t(4*count) { return -2 }

    // The exported C entry point has no caller-provided Odin context. Set one
    // before invoking helpers that allocate temporary slices.
    context = runtime.default_context()
    plan: SG_Plan
    defer sg_free_plan(&plan)
    if !sg_make_plan(&plan,n) { return -4 }
    left_input := make([]i64,count)
    right_input := make([]i64,count)
    defer delete(left_input); defer delete(right_input)
    for i := 0; i < count; i += 1 {
        left_input[i] = input[1+i]
        right_input[i] = input[1+count+i]
    }
    left, right, product: SG_Blocks
    defer sg_free_blocks(&left); defer sg_free_blocks(&right); defer sg_free_blocks(&product)
    if !sg_forward(&plan,n,left_input,&left) || !sg_forward(&plan,n,right_input,&right) { return -4 }
    sg_allocate_blocks(&plan.levels[n],&product)
    for shape := 0; shape < plan.levels[n].count; shape += 1 {
        d := plan.levels[n].items[shape].count
        for row := 0; row < d; row += 1 {
            for inner := 0; inner < d; inner += 1 {
                for col := 0; col < d; col += 1 {
                    index := row*d+col
                    product.items[shape][index] = (product.items[shape][index] +
                        left.items[shape][row*d+inner]*right.items[shape][inner*d+col])%SG_PRIME
                }
            }
        }
    }
    coefficients: []i64
    if !sg_inverse(&plan,n,&product,&coefficients) {
        delete(coefficients)
        return -4
    }
    defer delete(coefficients)
    if len(coefficients) != count { return -4 }
    for i := 0; i < count; i += 1 {
        value := u32(coefficients[i])
        for byte := 0; byte < 4; byte += 1 { output[4*i+byte] = u8((value >> u32(8*byte)) & 255) }
    }
    return i64(4*count)
}
