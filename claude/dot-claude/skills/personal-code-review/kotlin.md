# Jordan's Kotlin Review Patterns

Jordan focuses on code readability, async patterns correctness, and encouraging reusable abstractions while maintaining pragmatic follow-up suggestions rather than blocking on improvements.

## Reusable Abstractions & Standardization

**What to look for:** New utility functions or patterns that could benefit existing code elsewhere in the codebase.

**Why it matters:** Standardized patterns improve consistency, reduce bugs (e.g., preventing infinite loops in pagination), and make code easier to maintain.

**Example:** When a well-structured pagination helper is introduced, consider adopting it for existing pagination calls in follow-up PRs rather than leaving inconsistent patterns across the codebase.

## Async Pattern Selection in DGS/GraphQL

**What to look for:** Use of `runBlocking` + `.get()` vs `CompletableFuture.allOf()` when handling multiple async operations in DGS data fetchers.

**Why it matters:** `runBlocking` + `.get()` can cause deadlocks in DGS because blocking the request thread prevents DataLoader dispatch. The thread waits for a future that can never complete because DGS can't dispatch the DataLoader while the thread is blocked.

**Example:** Use `CompletableFuture.allOf()` to compose multiple futures:
```kotlin
// Correct: Non-blocking composition
val futures = items.map { computeAsync(it) }
return CompletableFuture.allOf(*futures.toTypedArray())
    .thenApply { futures.map { it.join() } }

// Wrong: Causes deadlock
runBlocking {
    items.map { computeAsync(it).get() }
}
```

## Contextual Comments for Non-Obvious Logic

**What to look for:** Code where the reasoning behind different handling of similar-looking data isn't immediately clear.

**Why it matters:** Explains architectural decisions that might otherwise confuse future maintainers or reviewers.

**Example:** When filtering one type of input (accounts as objects) but passing another directly (external entity IDs), document why: objects may be needed for metadata to compute values correctly, while IDs suffice when downstream services handle the logic.

## Receptive to Cleaner Alternatives

**What to look for:** Opportunities to suggest simpler implementations that the author may not be aware of.

**Why it matters:** Jordan appreciates learning cleaner approaches and adopts them readily, indicating a preference for the simplest correct solution.

**Example:** When a reviewer suggests a more idiomatic Kotlin or library-specific approach, adopt it if it's genuinely cleaner rather than defending the original implementation.

## Incremental Improvement Strategy

**What to look for:** Improvements that are valuable but not blocking for the current PR.

**Why it matters:** Keeps PRs focused while tracking technical debt. Separates "must fix now" from "nice to have in follow-up."

**Example:** Phrase non-blocking suggestions as "Could be nice to adopt it for existing calls in a follow-up PR" rather than requesting changes in the current PR.