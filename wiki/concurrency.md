# Concurrency

To execute a `.fun` concurrently in the background, the caller uses the `run` keyword. The developer may call `.wait()!` on the returned task to resolve the value. The compiler will throw an error if the developer attempts to `run` a method containing `mut self`, preventing data races.
