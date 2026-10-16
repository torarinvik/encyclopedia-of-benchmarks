package problem203

is_squarefree :: proc(number: i64) -> bool {
    copy := number
    for divisor := i64(2); divisor * divisor <= copy; divisor += 1 {
        multiplicity := 0
        for copy % divisor == 0 { copy /= divisor; multiplicity += 1 }
        if multiplicity >= 2 do return false
    }
    return true
}

@(export)
problem203 :: proc "c" (depth: i64) -> i64 {
    if depth > 51 do return -1
    row: [51]i64
    values: [1326]i64
    row[0] = 1
    values[0] = 1
    count := 1
    row_length := 1
    for row_index := i64(2); row_index <= depth; row_index += 1 {
        row[row_length] = 1
        for col := row_length - 1; col > 0; col -= 1 { row[col] += row[col - 1] }
        row[0] = 1
        row_length += 1
        for col := 0; col < row_length; col += 1 { values[count] = row[col]; count += 1 }
    }
    for i := 1; i < count; i += 1 {
        value := values[i]
        j := i
        for j > 0 && values[j - 1] > value { values[j] = values[j - 1]; j -= 1 }
        values[j] = value
    }
    total := i64(0)
    for i := 0; i < count; i += 1 {
        if i > 0 && values[i] == values[i - 1] do continue
        if is_squarefree(values[i]) { total += values[i] }
    }
    return total
}
