# Jordan's TypeScript Review Patterns

Jordan focuses on eliminating unnecessary code, avoiding over-mocking in tests, and ensuring consistent patterns across the codebase.

## Test Only Business Logic, Not Constants

**What to look for:** Tests that verify the values of constants, configuration arrays, or static data.

**Why it matters:** Tests should verify behavior and business logic, not that constants equal themselves. Testing constants adds maintenance burden without catching real bugs.

**Example:** Don't test that `AVATAR_COLORS` contains specific strings. Do test functions like `isValidAvatarColor()` that use those constants.

## Use Generated Mock Helpers

**What to look for:** Hand-written `createMock*` functions that construct test fixtures manually.

**Why it matters:** Auto-generated `mock<Entity>` helpers from test-utils libraries stay in sync with schema changes and reduce test maintenance.

**Example:** Instead of `const createMockNetWorthAccount = (overrides) => ({...})`, use `mockNetWorthAccount({ source: 'internal', id: 'account-1' })`.

## Avoid Unnecessary Mocking

**What to look for:** `jest.mock()` calls for child components, especially UI components that don't have side effects.

**Why it matters:** Mocking child components makes tests brittle and disconnected from real behavior. Only mock components with external dependencies (network, timers, etc.).

**Example:** Don't mock `<AccountAvatar>` just to render `null`. Let it render naturally unless it causes test failures.

## Remove Unnecessary useMemo

**What to look for:** `useMemo` wrapping simple object transformations or calculations that aren't computationally expensive.

**Why it matters:** Premature memoization adds complexity without performance benefits. React re-renders are usually fast enough without memoization.

**Example:** Simple object mappings like `{ [account.id]: { household: true } }` don't need `useMemo`.

## Remove Fallback Values for Non-Nullable Types

**What to look for:** Fallback patterns like `identityId ?? ''` when the value is typed as always present.

**Why it matters:** Unnecessary fallbacks obscure type guarantees and can mask real bugs. Trust your types.

**Example:** If `useIdentityId()` returns `string` (not `string | undefined`), use `identityId` directly.

## Consolidate Related useEffect Hooks

**What to look for:** Multiple `useEffect` hooks that handle related logic or could be combined.

**Why it matters:** Separate effects for related logic make code harder to follow and can introduce subtle bugs with dependency arrays.

## Test Behavioral Differences

**What to look for:** Tests that render different states but don't verify the actual behavioral difference.

**Why it matters:** If a test sets up "accounts that cannot update household," it should verify what's different about that state, not just that it renders.

## Clean Up TODO Comments

**What to look for:** TODO comments for "temporary logging" or debugging code that made it to review.

**Why it matters:** Debug logging should be removed before merge unless there's a documented reason to keep it.