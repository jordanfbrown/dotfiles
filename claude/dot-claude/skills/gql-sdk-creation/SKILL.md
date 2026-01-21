---
name: gql-sdk-creation
description: Create new GraphQL SDK query/mutation packages in front-end-monorepo. Use when adding new GraphQL operations. Covers NX generator usage, query/fragment files, and code generation.
---

# Creating GraphQL SDK Operations (front-end-monorepo)

## Process

### 1. Use NX Generator

**Never manually create packages.** Always use the generator:

```bash
nx g @wealthsimple/ws-nx:gql-sdk-operation <package-name> --operation=query --libraryOwner=<team-name>
```

**Parameters:**
- `<package-name>`: kebab-case name (e.g., `account-holdings`, `user-preferences`)
- `--operation`: `query` or `mutation`
- `--libraryOwner`: team name for CODEOWNERS

**Example:**
```bash
nx g @wealthsimple/ws-nx:gql-sdk-operation account-target-portfolio --operation=query --libraryOwner=invest
```

### 2. Update generated files

The generator creates files in `libs/shared/gql-operations/queries/gql-sdk-<package-name>/src/`:

**Query file** (`<package-name>.query.gql.ts`):
```typescript
import { gql } from '@wealthsimple/gql-sdk-core';

export const ACCOUNT_TARGET_PORTFOLIO_QUERY = gql`
  query AccountTargetPortfolio($accountId: ID!) {
    account(id: $accountId) {
      id
      ...AccountTargetPortfolioFields
    }
  }
`;
```

**Fragment file** (`<package-name>.fragment.gql.ts`):
```typescript
import { gql } from '@wealthsimple/gql-sdk-core';

export const ACCOUNT_TARGET_PORTFOLIO_FRAGMENT = gql`
  fragment AccountTargetPortfolioFields on Account {
    id
    targetPortfolioV2 {
      id
      name
      allocations {
        assetClass
        percentage
      }
    }
  }
`;
```

### 3. Download schemas

Ensure you have latest GraphQL schemas:

```bash
pnpm download-schemas
```

### 4. Generate types

```bash
pnpm nx run gql-sdk-<package-name>:gql-generate
```

This creates:
- TypeScript types for query/mutation
- `use<PackageName>` hook
- `use<PackageName>Suspended` hook (for Suspense)
- Test utilities in `test-utils/generated.ts`

### 5. Export from package

Verify `src/index.ts` exports the hooks:

```typescript
export * from './generated';
export * from './<package-name>.fragment.gql';
```

## Generated Hook Usage

```typescript
import { useAccountTargetPortfolio } from '@wealthsimple/gql-sdk-account-target-portfolio';

const { data, loading, error } = useAccountTargetPortfolio({
  variables: { accountId: 'acc-123' },
});
```

## Test Utils

The generator also creates test utilities:

```typescript
import {
  mockUseAccountTargetPortfolio,
  mockAccountTargetPortfolioFields
} from '@wealthsimple/gql-sdk-account-target-portfolio-test-utils';

mockServer.use(
  mockUseAccountTargetPortfolio(() => ({
    account: {
      id: 'acc-123',
      ...mockAccountTargetPortfolioFields(),
    },
  })),
);
```

## Common Issues

### Schema not found
```
Error: Unknown type "SomeType"
```
Run `pnpm download-schemas` to get latest schemas.

### Missing fragment
```
Error: Unknown fragment "MyFields"
```
Ensure fragment is imported in query file and exported from index.

### Circular dependency
Check that you're not importing from packages that import from this one.

## Commands

```bash
# Create new operation
nx g @wealthsimple/ws-nx:gql-sdk-operation <name> --operation=query --libraryOwner=<team>

# Download schemas
pnpm download-schemas

# Generate types
pnpm nx run gql-sdk-<name>:gql-generate

# Test the package
pnpm nx run gql-sdk-<name>:test

# Check types
pnpm nx run gql-sdk-<name>:check-types
```
