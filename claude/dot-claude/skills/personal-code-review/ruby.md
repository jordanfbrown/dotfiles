# Jordan's Ruby Review Patterns

Jordan focuses on API design simplicity, defensive coding practices, and ensuring code behavior is explicit rather than implicit. Reviews emphasize questioning complexity and understanding the "why" behind implementations.

## Simplify Responsibility and Reduce Coupling

**What to look for:** Methods or classes that take parameters they don't need to use directly, or responsibilities that could be split differently.

**Why it matters:** Simpler interfaces are easier to test, understand, and maintain.

**Example:** Instead of passing `logger` and `log_data` to a method that determines log level, have it return the level (`:info`, `:warn`, `:error`) and let the caller handle logging: `logger.send(level, log_data)`.

## Be Explicit About Default Behaviors

**What to look for:** Switch/case statements with implicit `else` branches, magic numbers without explanation, or default values that could surprise future maintainers.

**Why it matters:** Implicit defaults can mask bugs when new cases are added later.

**Example:** When a case statement defaults to `error` logging, consider whether new categories should default to a safer level like `info`, or be explicit about all known cases. Add comments explaining magic numbers like `depth > 5`.

## Question Necessity and Naming

**What to look for:** New namespaces, modules, or abstractions that might be unnecessary; variable names that don't reflect their current type/purpose.

**Why it matters:** Unnecessary complexity adds cognitive load; accurate names prevent confusion.

**Example:** "Curious why we need this namespace vs. just using `AggregatorClients::Logger`?" When a variable changes from single value to array, rename it (e.g., `component` → `components`).

## Validate Sensitive Operations

**What to look for:** Logging statements that include raw data, regex patterns for validation (especially email), error codes being classified without documented meaning.

**Why it matters:** PII can leak into logs; validation logic is easy to get wrong; undocumented error codes become tribal knowledge.

**Example:** "Is it ok to log this?" for contact data. "Email regex is usually quite hard to do correctly. Is this matching existing logic?" "Do we know what this error represents?" for new error codes.

## Prefer Standard Library Solutions

**What to look for:** Manual mutex management, custom caching implementations, or patterns that have well-tested library alternatives.

**Why it matters:** Standard solutions reduce bugs and maintenance burden.

**Example:** Use `Concurrent::Map` instead of managing mutex manually for thread-safe caching.

## Ensure Tests Actually Execute

**What to look for:** Tests with `skip` conditions that find data dynamically, or test patterns that might never match real data.

**Why it matters:** Tests that skip silently provide false confidence.

**Example:** When tests use `skip 'No institution with this pattern'`, verify the pattern actually gets hit in practice.