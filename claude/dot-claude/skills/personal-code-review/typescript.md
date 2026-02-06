# Jordan's TypeScript Review Patterns

Jordan focuses on eliminating unnecessary code, avoiding over-mocking in tests, and ensuring consistent patterns across the codebase.

## Use Generated Mock Helpers

**What to look for:** Hand-written `createMock*` functions, manual object construction with explicit `__typename`, or field-by-field mock definitions.

**Why it matters:** Auto-generated `mock<FragmentName>` helpers stay in sync with schema changes, provide sensible defaults, and reduce test maintenance. Custom mocks become stale and require manual updates when schemas evolve.

**Example:** Instead of `{ __typename: 'Account', id: '123', ... }` or custom `createMockNetWorthAccount()`, use `mockNetWorthAccount({ id: '123' })` from test-utils.

## Avoid Unnecessary Mocking

**What to look for:** `jest.mock()` calls for child components, especially UI components that just return null or a simple div.

**Why it matters:** Mocking children tests implementation details rather than behavior and reduces test fidelity. Only mock components with external dependencies (network, timers, etc.).

**Example:** Question whether `jest.mock('../account-avatar.component', () => ({ AccountAvatar: () => null }))` is actually needed before adding it.

## Remove Unnecessary useMemo/useCallback

**What to look for:** `useMemo` or `useCallback` wrapping simple object transformations, boolean checks, string formatting, or non-expensive calculations.

**Why it matters:** Premature memoization adds complexity and overhead without benefits. React's rendering is fast enough for most transformations.

**Example:** Simple mappings like `{ [account.id]: { household: true } }` or settings object transformations don't need memoization unless profiling shows a bottleneck.

## Remove Fallbacks for Non-Nullable Types

**What to look for:** Fallback patterns like `identityId ?? ''` when typed as always present, or type guards for impossible cases.

**Why it matters:** Unnecessary fallbacks obscure type guarantees, suggest the types are wrong, and can hide bugs where values are unexpectedly undefined.

**Example:** If `useIdentityId()` returns `string` in authenticated contexts, use `identityId` directly without fallbacks.

## Test Business Logic, Not Constants

**What to look for:** Tests verifying constant values, array lengths of static data, or rendering states without asserting behavioral differences.

**Why it matters:** Tests should verify behavior and transformations, not that constants haven't changed. If a test sets up a special state, it should verify what makes that state different.

**Example:** Don't test that `AVATAR_COLORS` contains specific strings. Do test `isValidAvatarColor()` that uses those constants.

## Consolidate Related Logic

**What to look for:** Multiple `useEffect` hooks with related concerns, or multiple state variables tracking mutually exclusive states.

**Why it matters:** Scattered effects are harder to follow and can create subtle timing issues. Combining related logic prevents impossible states.

**Example:** Instead of `[showDelete, setShowDelete]`, `[showEdit, setShowEdit]`, use `[activeSheet, setActiveSheet]` with type `'delete' | 'edit' | null`.

## Prefer Derived Values Over Flags

**What to look for:** Boolean props like `isLinked` passed alongside data that already contains that information.

**Why it matters:** Derive from source data rather than passing redundant flags that can become inconsistent.

**Example:** Use `account.source === 'linked'` instead of passing a separate `isLinked` prop.

## Clean Up Debug Code

**What to look for:** TODO comments for "temporary logging" or debug code that made it to review.

**Why it matters:** Debugging artifacts clutter code and can impact performance in production. Remove before merge unless documented.