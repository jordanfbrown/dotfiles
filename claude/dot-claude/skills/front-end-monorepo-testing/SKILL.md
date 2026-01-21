---
name: front-end-monorepo-testing
description: Use when user says "write a test for this component" or asks to create/update test files for React components in front-end-monorepo. Covers web and mobile testing patterns, async handling, mocking, and common pitfalls.
---

# Testing React Components in front-end-monorepo

## Critical Rule: Investigate Before Mocking

**NEVER mock anything without first checking what existing tests do.**

Before writing any `jest.mock()` call:
1. Search for similar test files in the same package
2. Check what test wrapper utilities provide
3. Grep for the module/hook name to see if others mock it

```bash
# Find test files in package
find libs/path/to/package -name "*.test.tsx"

# See if others mock this module
grep -r "jest.mock.*module-name" libs/path/to/package/

# Check for feature flag usage
grep -r "FeatureFlag.initialize" libs/path/to/package/
```

If no other tests mock something, you probably don't need to either.

## Required Imports & Setup

### Web
```tsx
/**
 * @jest-environment jsdom
 */
import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { getMockProviderStack } from '@wealthsimple/jstools-test-web';
import { mockServer } from '@wealthsimple/jest-msw';
import { FeatureFlag } from '@wealthsimple/feature-flag-ts';
```

### Mobile (React Native)
```tsx
import React from 'react';
import { render, screen, waitFor } from '@testing-library/react-native';
import { getMockProviderStack } from '@wealthsimple/jstools-test-mobile';
import { getMockProviderStackWithEquitiesContext } from '@wealthsimple/sdi-orders-mobile';
import { mockServer } from '@wealthsimple/jest-msw';
import { FeatureFlag } from '@wealthsimple/feature-flag-ts';
```

## Auth Setup: Web vs Mobile

Different patterns for mocking identity/auth:

### Mobile
```tsx
import { setupAuthInfoForTest } from '@wealthsimple/auth-info-test-utils';

// Call at module level (outside describe block)
// Uses default identityId: 'identity-123'
setupAuthInfoForTest();
```

### Web
```tsx
import { mockWebIdentityId } from '@wealthsimple/web-auth-test-utils';

// Call at module level or in beforeEach
mockWebIdentityId();
```

## Async Waiting: Use TestIDs, Not Text

**BAD** - Text content can change, be duplicated, or load async:
```tsx
expect(await screen.findByText('Smith Family')).toBeInTheDocument();
```

**GOOD** - TestIDs are stable and unique:
```tsx
expect(await screen.findByTestId('net-worth-display')).toBeInTheDocument();
// Then use sync queries for text assertions
expect(screen.getByText('Smith Family')).toBeInTheDocument();
```

**Pattern**: Wait for a testid, then assert on content synchronously.

## Mock Child Components with TestIDs

When mocking child components, add `data-testid` for reliable selection:

```tsx
jest.mock('../child-component/child.component', () => ({
  ChildComponent: () => (
    <div data-testid="child-component">Mocked Child</div>
  ),
}));
```

## GraphQL Mocking

Use `mockServer` with SDK test utilities.

### Required Base Mocks (Almost All Tests Need These)

```tsx
import {
  mockUseIdentityPackages,
  mockUseLatestClientSubscriptions,
} from '@wealthsimple/gql-sdk-test-utils';

beforeEach(() => {
  mockServer.use(
    mockUseIdentityPackages(),
    mockUseLatestClientSubscriptions(),
    // Add component-specific mocks...
  );
});
```

### Component-Specific Mocks

```tsx
import { mockUseIdentityHousehold } from '@wealthsimple/gql-sdk-identity-household-test-utils';

beforeEach(() => {
  mockServer.use(
    mockUseIdentityPackages(),
    mockUseLatestClientSubscriptions(),
    mockUseIdentityHousehold(() => ({
      identity: {
        id: 'identity-123',
        household: {
          id: 'household-123',
          name: 'Test Household',
          members: [],
        },
      },
    })),
  );
});
```

## Feature Flag Testing

```tsx
beforeEach(() => {
  FeatureFlag.initialize({ 'feature-flag-name': true });
});

describe('when feature is disabled', () => {
  beforeEach(() => {
    FeatureFlag.initialize({ 'feature-flag-name': false });
  });

  it('renders fallback UI', async () => {
    // ...
  });
});
```

## Context Providers

Wrap components that need context:

```tsx
function renderComponent({ isHousehold = true } = {}) {
  return render(
    <NetWorthProvider isHousehold={isHousehold}>
      <MyComponent />
    </NetWorthProvider>,
    getMockProviderStack(),
  );
}
```

## Testing Suspense-Enabled Components

If the component uses suspense-enabled data fetching (e.g., hooks that suspend while loading), you must use `renderAsync` and wrap with `<Suspense>`:

```tsx
import { Suspense } from 'react';
import { renderAsync, getMockProviderStack } from '@wealthsimple/jstools-test-web';

async function renderComponent({ isHousehold = true } = {}) {
  const { wrapper: Wrapper } = getMockProviderStack();

  return renderAsync(
    <Wrapper>
      <Suspense fallback={<div>Loading...</div>}>
        <NetWorthProvider isHousehold={isHousehold}>
          <MyComponent />
        </NetWorthProvider>
      </Suspense>
    </Wrapper>,
  );
}

// Tests must await the render
it('renders content', async () => {
  await renderComponent();
  expect(await screen.findByTestId('content')).toBeInTheDocument();
});
```

**Signs you need this pattern:**
- Component uses `useSuspenseQuery` or similar
- Tests fail with empty `<body><div /></body>`
- Console shows "A component suspended inside an `act` scope"

## Handling Multiple Elements with Same Text

When text appears multiple times (e.g., header + segmented control):

```tsx
// BAD - will throw "multiple elements" error
expect(screen.getByText('Household')).toBeInTheDocument();

// BETTER - be more specific with role or container
expect(screen.getByRole('button', { name: 'Household' })).toBeInTheDocument();
```

## Don't Overtest

Keep tests focused on key behaviors:

1. **Core rendering** - Component mounts and shows main elements
2. **Conditional rendering** - Different states show different UI
3. **Feature flags** - Fallback UI when features are disabled

**Avoid**:
- Testing implementation details
- Complex interaction tests that are flaky
- Testing third-party component internals

## Test Structure Template

```tsx
/**
 * @jest-environment jsdom
 */
import React from 'react';
import { render, screen } from '@testing-library/react';
import { getMockProviderStack } from '@wealthsimple/jstools-test-web';
import { mockServer } from '@wealthsimple/jest-msw';
import { FeatureFlag } from '@wealthsimple/feature-flag-ts';
// Import mocks and component...

// Mock external dependencies
jest.mock('@wealthsimple/web-auth', () => ({
  useIdentityId: () => 'identity-123',
}));

// Mock child components
jest.mock('./child.component', () => ({
  Child: () => <div data-testid="child">Child</div>,
}));

// Render helper
function renderComponent(props = {}) {
  return render(
    <MyComponent {...props} />,
    getMockProviderStack(),
  );
}

describe('MyComponent', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    FeatureFlag.initialize({ 'my-feature': true });
    mockServer.use(/* GraphQL mocks */);
  });

  it('renders core elements', async () => {
    renderComponent();
    expect(await screen.findByTestId('main-element')).toBeInTheDocument();
  });

  it('shows conditional content when prop is true', async () => {
    renderComponent({ showExtra: true });
    expect(await screen.findByTestId('main-element')).toBeInTheDocument();
    expect(screen.getByTestId('extra-content')).toBeInTheDocument();
  });

  describe('when feature is disabled', () => {
    beforeEach(() => {
      FeatureFlag.initialize({ 'my-feature': false });
    });

    it('renders fallback UI', async () => {
      renderComponent();
      expect(await screen.findByTestId('fallback')).toBeInTheDocument();
    });
  });
});
```

## Running Tests

```bash
# Single file
pnpm test <filepath>

# Project tests
pnpm nx run <project-name>:test

# Single file in project
pnpm nx run <project-name>:test --testFile=<path>
```

## Required Verification: Lint AND Type Check

**Before considering test work complete, you MUST run both the linter AND type checker.**

```bash
# Run linter on the project
pnpm nx run <project-name>:lint

# Run type checker on the project
pnpm nx run <project-name>:check-types

# Or run both together
pnpm nx run <project-name>:lint && pnpm nx run <project-name>:check-types
```

Common type errors in tests:
- Missing type imports from `@wealthsimple/gql-generated`
- Wrong enum values (use actual GraphQL enum, not string literals)
- Mock functions missing proper return types
- Props not matching component interface

**Fix all lint and type errors before marking the task complete.**

## Anti-Patterns to Avoid

### Mocking Navigation (Mobile)

**WRONG:**
```tsx
jest.mock('@react-navigation/native', () => ({
  useNavigation: () => ({ navigate: jest.fn() }),
}));
```

**RIGHT:**
```tsx
// Navigation is already mocked by the wrapper
const { wrapper, mockNavigation } = getMockProviderStackWithEquitiesContext({...});
// Use mockNavigation.navigate, mockNavigation.goBack, etc.
```

### Mocking Feature-Flagged Hooks

**WRONG:**
```tsx
jest.mock('@wealthsimple/options-mobile', () => ({
  usePreFlightCheckMobile: jest.fn(() => false),
}));
```

**RIGHT:**
```tsx
FeatureFlag.initialize({ 'mobile-options-pre-flight-check-integration': false });
```

### Multiple Assertions in waitFor

**WRONG** (linter: `testing-library/no-wait-for-multiple-assertions`):
```tsx
await waitFor(() => {
  expect(screen.getByText('Max')).toBeTruthy();
  expect(screen.getByText('Review')).toBeTruthy();
});
```

**RIGHT:**
```tsx
await waitFor(() => {
  expect(screen.getByText('Review')).toBeTruthy();
});
expect(screen.getByText('Max')).toBeTruthy();
```

### Mocking Implementation Instead of Data

**WRONG:**
```tsx
jest.mock('../../utils/calculate-total', () => ({
  calculateTotal: jest.fn(() => 100),
}));
```

**RIGHT** (mock the data layer):
```tsx
mockServer.use(
  mockUseSecurityQuoteV2(() => mockSecurityQuoteV2({ ask: '100.10', bid: '100.00' })),
);
```

### Mocking i18n Translation Strings

**WRONG** - Don't mock translated strings, it couples tests to implementation:
```tsx
const mockGetMessage = jest.fn((key: string, values?: { name: string }) => {
  const translations: Record<string, string> = {
    'my-key::title': 'Welcome',
    'my-key::greeting': `Hello ${values?.name}`,
  };
  return translations[key] ?? key;
});

expect(result).toBe('Welcome'); // Fragile - breaks if translation changes
```

**RIGHT** - Just return the key and assert on what key was called:
```tsx
const mockGetMessage = jest.fn((key: string) => key);

myFunction(mockGetMessage);

expect(mockGetMessage).toHaveBeenCalledWith('my-key::title');
expect(mockGetMessage).toHaveBeenCalledWith('my-key::greeting', { name: 'Alice' });
```

This tests the correct locale key is used without coupling to the actual translation text.

### Wrong TypeScript Enum Values

**WRONG:**
```tsx
const marginAccount = mockAccountWithLink({ unifiedAccountType: 'MARGIN' });
```

**RIGHT** (use actual enum from gql-generated):
```tsx
const marginAccount = mockAccountWithLink({
  unifiedAccountType: 'SELF_DIRECTED_NON_REGISTERED_MARGIN',
});
```

## Quick Reference: What NOT to Mock

| Don't Mock | Use Instead |
|------------|-------------|
| `useNavigation` | `mockNavigation` from wrapper |
| `usePreFlightCheckMobile` | `FeatureFlag.initialize()` |
| Utility functions | Real implementation with mocked data |
| `useFormContext` | Wrapper provides form context |
| GraphQL hooks | MSW with `mockUse*` utilities |
| i18n translation strings | Return key, assert on `toHaveBeenCalledWith` |

## Common Pitfalls

1. **Forgetting `React` import** - JSX requires React in scope
2. **Using `findByText` for async** - Prefer `findByTestId` for stability
3. **Not waiting for async** - Always `await findBy*` before sync assertions
4. **Testing click on complex components** - Segmented controls, dropdowns may be flaky
5. **Asserting on localized text** - Text may change; prefer testids or roles
6. **Testing loading states with MSW** - MSW mocks resolve almost instantly, so you can't reliably test loading indicators
7. **Unnecessary helper functions** - Just call `mockX()` directly, use spread for overrides

## Import Order

Follow this import order to pass lint:

```tsx
import React from 'react';
import type { useHistory } from 'react-router-dom'; // type imports after React
import { render, screen } from '@testing-library/react';
// ... other imports
import { MyComponent } from './my-component'; // local imports last
```

## Mocking History (react-router-dom)

For components that receive `history` as a prop:

```tsx
const mockPush = jest.fn();

// In render - cast to unknown first to avoid type errors
<MyComponent
  history={{ push: mockPush } as unknown as ReturnType<typeof useHistory>}
  goToState={mockGoToState}
/>
```

## GraphQL Mutation Mocking

For mutations, use the SDK test utilities with success/error responses:

```tsx
import { mockUseInvitationResend } from '@wealthsimple/gql-sdk-invitation-resend-test-utils';
import { mockUseInvitationCancel } from '@wealthsimple/gql-sdk-invitation-cancel-test-utils';

// Success response
mockServer.use(
  mockUseInvitationResend(() => ({
    invitationResend: {
      __typename: 'InvitationResent',
      invitation: { id: 'inv-123', status: InvitationStatusEnum.PENDING },
    },
  })),
);

// Error response
mockServer.use(
  mockUseInvitationCancel(() => ({
    invitationCancel: {
      __typename: 'InvitationResultInvitationNotFoundError',
    },
  })),
);
```

## Suppressing Known Console Errors

If a component has pre-existing console errors (e.g., React key warnings), suppress them to avoid CI failures:

```tsx
const originalConsoleError = console.error;
beforeAll(() => {
  console.error = (...args: unknown[]) => {
    const message = typeof args[0] === 'string' ? args[0] : '';
    if (message.includes('Each child in a list should have a unique "key" prop')) {
      return;
    }
    originalConsoleError(...args);
  };
});

afterAll(() => {
  console.error = originalConsoleError;
});
```

## Mock Data Patterns

Create a default mock object and spread to override specific fields:

```tsx
const DEFAULT_INVITATION = mockSentInvitations({
  id: 'invitation-456',
  inviteeEmail: 'partner@example.com',
  inviteeName: 'Partner Name',
  status: InvitationStatusEnum.PENDING,
  sentAt: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString(),
});

// Use directly for most tests
mockServer.use(
  mockUseSentInvitations(() => ({
    sentInvitations: [DEFAULT_INVITATION],
  })),
);

// Override specific fields when needed
mockServer.use(
  mockUseSentInvitations(() => ({
    sentInvitations: [
      mockSentInvitations({
        ...DEFAULT_INVITATION,
        sentAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // different time
      }),
    ],
  })),
);
```

## Debugging Failed Tests

### "Unhandled MSW Request"
```
captured a request without a matching request handler
```
Add missing mock to `mockServer.use()`. Check if you need `mockUseIdentityPackages()` or `mockUseLatestClientSubscriptions()`.

### "Component Behaves Differently Than Expected"
Check mock data uses correct TypeScript types/enums. Search for constants in `@wealthsimple/gql-generated`.

### "Hook Returns Undefined"
```
useNavigation returns undefined
```
Check what the test wrapper provides. Don't mock it yourself.

### Common Mock Utilities by Domain

**Accounts:**
```tsx
import { mockUseAccount, mockAccountWithLink, mockAccountFeature } from '@wealthsimple/gql-sdk-test-utils';
```

**Securities:**
```tsx
import { mockUseSecurity, mockSecurity } from '@wealthsimple/gql-sdk-security-test-utils';
import { mockUseSecurityQuoteV2, mockSecurityQuoteV2 } from '@wealthsimple/gql-sdk-security-quote-v2-test-utils';
```

**Trading:**
```tsx
import { mockUseTradingBalanceView, mockTradingBalanceView } from '@wealthsimple/gql-sdk-trading-balance-view-test-utils';
```
