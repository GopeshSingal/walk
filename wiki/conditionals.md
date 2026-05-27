# Conditionals

Walk discard requires parentheses aroudn conditions. Braces `{}` are strictly requires around conditional bodies.

```
if user.age >= 18 {
    user.activate()
} else if user.age > 13 {
    user.send_parental_consent()
} else {
    user.block()
}
```

## Unwrapping Optionals

Optionals (`?`) and Errors(`!`) must be explicitly handled. Conditionals are used to safely unwrap these states.

```
# user.nickname is a String? (Optional)
if let name = user.nickname {
    print(name) # 'name' is statically guaranteed to be a valid string here
} else {
    print("No nickname provided!")
}
```

```
# fetch_data.fun can throw an error (!)
let data = network.fetch_data() else {
    # This block MUST return or crash; it cannot continue normally
    return "Fallback Data"
}
```
