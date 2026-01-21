---
name: feature-flag-removal
description: Remove useRolloutFlag feature flags from front-end-monorepo. Use when cleaning up feature flags after rollout. Covers finding usages, removing conditionals, and cleanup verification.
---

# Feature Flag Removal (front-end-monorepo)

For `useRolloutFlag` hook removals only.

## Process

### 1. Find all usages

```bash
# Find all references to the flag
grep -r "feature-flag-name" libs/ apps/ --include="*.ts" --include="*.tsx"

# Find hook usages specifically
grep -r "useRolloutFlag.*feature-flag-name" libs/ apps/ --include="*.ts" --include="*.tsx"
```

### 2. Determine flag value

**Default**: Assume flag value is `true` (feature enabled) unless told otherwise.

### 3. Remove flag and simplify code

**Before:**
```typescript
const isEnabled = useRolloutFlag('feature-name', {
  owner: 'team',
  fallbackValue: false
});

if (isEnabled) {
  enabledFunction();
} else {
  disabledFunction();
}
```

**After (flag=true):**
```typescript
enabledFunction();
```

### 4. Clean up thoroughly

Remove ALL associated code:
- The `useRolloutFlag` import (if no longer used)
- The flag variable declaration
- The conditional branches
- The disabled code path entirely
- Any comments referencing the flag

**Don't leave dead code** - remove the else branch completely, not just the conditional.

### 5. Verify changes

```bash
# Run lint, types, and tests on affected projects
pnpm nx run-many -t lint,check-types,test -p <project1>,<project2>

# Check for unused code
pnpm unimported --quiet
```

## Example Transformations

### Simple conditional
```typescript
// Before
const showNewUI = useRolloutFlag('new-ui', { owner: 'team', fallbackValue: false });
return showNewUI ? <NewComponent /> : <OldComponent />;

// After (flag=true)
return <NewComponent />;
```

### Early return pattern
```typescript
// Before
const isEnabled = useRolloutFlag('feature', { owner: 'team', fallbackValue: false });
if (!isEnabled) {
  return <LegacyView />;
}
return <ModernView />;

// After (flag=true)
return <ModernView />;
```

### Feature in hook
```typescript
// Before
const useMyHook = () => {
  const hasFeature = useRolloutFlag('my-feature', { owner: 'team', fallbackValue: false });
  return hasFeature ? newBehavior() : oldBehavior();
};

// After (flag=true)
const useMyHook = () => {
  return newBehavior();
};
```

## Common Mistakes

1. **Leaving the variable** - Don't just remove the conditional, remove the flag variable too
2. **Keeping dead imports** - Remove `useRolloutFlag` import if no longer used in file
3. **Not running unimported** - May leave orphaned files from old code path
4. **Forgetting tests** - Tests may also have flag setup to remove

## Commands

```bash
# Find all flag usages
grep -r "flag-name" libs/ apps/ --include="*.ts" --include="*.tsx"

# Run checks on affected projects
pnpm nx run-many -t lint,check-types,test -p <projects>

# Find unused code
pnpm unimported --quiet
```
