# Loops

## Range/Iterator Loops (`for ... in`)

Used for safely iterating over arrays, memory arenas, or numeric ranges without exposing raw index math
```
# Numeric range iteration
for i in 0..10 {
    print(i)
}

# Array/Struct iteration
for item in shopping_cart.items {
    item.calculate_tax()
}
```

## Condition Loop (`while`)
Used when the number of conditions is unknown, but is tied to a specific state.
```
while queue.is_active() {
    let job = queue.pop()
    job.execute()
}
```

## Infinite Loop (`loop`)
An explicit infinite loop for systems programming
```
loop {
    let request = server.listen()
    if request.is_shutdown {
            break
    }
    server.handle(request)
}
```
