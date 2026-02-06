# Jordan's Ruby Review Patterns

Jordan focuses on API design simplicity, defensive coding practices, and ensuring code behavior is explicit rather than implicit. Reviews emphasize questioning complexity and understanding the "why" behind implementations.

## Simplify Responsibility and Reduce Coupling

**What to look for:** Methods that take parameters just to pass them through, or responsibilities that could be split differently.

**Why it matters:** Simpler interfaces are easier to test, understand, and maintain.

**Example:** Instead of passing `logger` and `log_data` to a method that determines log level, have it return the level (`:info`, `:warn`, `:error`) and let the caller handle logging: `logger.send(level, log_data)`.

## Be Explicit About Default Behaviors

**What to look for:** Switch/case statements with implicit `else` branches, magic numbers without explanation, or default values that could surprise future maintainers.

**Why it matters:** Implicit defaults can mask bugs when new cases are added. Ask: "What are the `else` cases here?" and "Should we default to a safer level if one is missing?"

**Example:** When a case statement defaults to `error` logging, consider whether new categories should default to a safer level like `info`, or be explicit about all known cases. Add comments explaining magic numbers like `depth > 5` or extract to named constants.

## Question Silent Fallbacks

**What to look for:** Rescue blocks that log and return fallback data, methods that silently degrade functionality.

**Why it matters:** Showing partial data may confuse users more than showing an error.

**Example:** When fetching household accounts fails, consider whether failing loudly is better than silently returning only the user's own accounts.

## Question Necessity and Naming

**What to look for:** New namespaces or abstractions that might be unnecessary; variable names that don't reflect their current type/purpose; overlapping parameters representing the same concept.

**Why it matters:** Unnecessary complexity adds cognitive load; accurate names prevent confusion.

**Example:** "Curious why we need this namespace?" When a variable changes from single value to array, rename it (`component` → `components`). Consolidate `flow_type: 'refresh'` and `is_refresh: true` into one parameter.

## Validate Sensitive Operations

**What to look for:** Logging statements that include raw data, regex patterns for validation (especially email), error codes being classified without documented meaning.

**Why it matters:** PII can leak into logs; validation logic is easy to get wrong; undocumented error codes become tribal knowledge.

**Example:** "Is it ok to log this?" for contact data. "Email regex is usually quite hard to do correctly. Is this matching existing logic?"

## Verify Inheritance and Existing Patterns

**What to look for:** Including modules or concerns that might already be available through inheritance.

**Why it matters:** Avoid redundant code and maintain consistency with existing architecture.

**Example:** Before adding `include ComponentLoggingConcern`, check: "Does it not inherit from `ApplicationController`?"

## Prefer Standard Library Solutions

**What to look for:** Manual mutex management, custom caching implementations, hand-built YAML generation.

**Why it matters:** Standard solutions reduce bugs and maintenance burden.

**Example:** Use `Concurrent::Map` instead of managing mutex manually; use `.to_yaml` instead of building YAML strings.

## Remove Unused Code Completely

**What to look for:** Methods unused after refactoring, commented-out code, backwards-compatibility shims.

**Why it matters:** Dead code creates confusion and maintenance burden.

**Example:** If `find_by_fuzzy_match` is no longer called after introducing caching, delete it entirely.

## Test Behavior, Not Implementation

**What to look for:** Tests that mock internal methods of the class under test, verify implementation details rather than outcomes, or use `skip` with dynamic conditions.

**Why it matters:** Implementation-focused tests break during refactoring even when behavior is correct. Conditional skips may mean tests never actually run.

**Example:** Instead of `expect(service).to receive(:remove_personal_data)`, verify that the `RemovedMembers` event was actually created. Question whether `skip if institution.nil?` means the test provides real value.