---
name: fort-knox-component-architecture
description: Structure code in fort-knox components using Clean Architecture patterns. Use when creating new components, adding use cases, repositories, adapters, or services. Clarifies when to use use_cases vs strategies vs services.
---

# Fort Knox Component Architecture

Fort Knox uses Clean Architecture / Hexagonal Architecture in a Modular Monolith. Components are bounded contexts with enforced boundaries via Packwerk.

## Quick Reference: Where Does This Code Go?

| You're writing... | Put it in... |
|-------------------|--------------|
| Business workflow orchestration | `domain/use_cases/` |
| Interchangeable algorithm/approach | `domain/strategies/` |
| Data access (CRUD) | `domain/repositories/` |
| External concept → domain mapping | `adapters/` |
| External API client calls | `services/` |
| Public entry point | `public/` |

## The Layer Stack

```
public/           ← Entry points (APIs, GraphQL, Structs)
    ↓
domain/           ← Business logic (use_cases, repos, strategies)
    ↓
adapters/         ← Translation (ActiveRecord → Struct)
    ↓
services/         ← Low-level utilities (API clients)
    ↓
models/           ← ActiveRecord (data persistence)
```

## Use Cases vs Strategies vs Services

This is the most confusing part. Here's how to distinguish them:

### Use Cases: "What the system does"

A use case **orchestrates a business operation**. It coordinates multiple steps but doesn't contain the logic itself.

```ruby
# domain/use_cases/process_deposit.rb
module FundingIntents
  module UseCases
    class ProcessDeposit
      extend Dry::Initializer

      option :deposit_repository, default: proc { Repositories::ActiveRecordDepositRepository.new }
      option :posting_strategy_factory, default: proc { Strategies::PostingStrategyFactory.new }
      option :event_bus, default: proc { Events::EventBus.instance }

      def call(deposit_id:)
        # 1. Fetch data (delegates to repository)
        deposit = deposit_repository.find!(deposit_id: deposit_id)

        # 2. Select strategy (delegates to factory)
        strategy = posting_strategy_factory.build(deposit: deposit)

        # 3. Execute business logic (delegates to strategy)
        result = strategy.call(deposit: deposit)

        # 4. Publish events (side effect)
        if result.success?
          event_bus.publish(:deposit_processed, deposit_id: deposit_id)
        end

        result
      end
    end
  end
end
```

**Key traits:**
- Named as verb phrases: `ProcessDeposit`, `SaveAnnotation`, `ChargeAccountFees`
- Orchestrates, doesn't implement
- Uses dependency injection for all external concerns
- Single `call` method

### Strategies: "How to do something specific"

A strategy **implements business logic** when there are multiple ways to do the same thing.

```ruby
# domain/strategies/abstract_posting_strategy.rb
module FundingIntents
  module Strategies
    class AbstractPostingStrategy
      extend Dry::Initializer

      def call(deposit:)
        raise NotImplementedError
      end
    end
  end
end

# domain/strategies/immediate_posting_strategy.rb
module FundingIntents
  module Strategies
    class ImmediatePostingStrategy < AbstractPostingStrategy
      def call(deposit:)
        # Actual business logic for immediate posting
        ledger_instructions = build_instructions(deposit)
        post_to_ledger(ledger_instructions)
      end

      private

      def build_instructions(deposit)
        # Complex business rules live HERE
      end
    end
  end
end

# domain/strategies/delayed_posting_strategy.rb
module FundingIntents
  module Strategies
    class DelayedPostingStrategy < AbstractPostingStrategy
      def call(deposit:)
        # Different business logic for delayed posting
        schedule_for_later(deposit)
      end
    end
  end
end
```

**Key traits:**
- Class name describes the variant and ends in `Strategy`: `ImmediatePostingStrategy`, `EftPostingStrategy`, `FullInKindStrategy`
- Contains actual business logic
- Interchangeable via common interface
- Selected by a Factory based on conditions
- Use `Abstract*Strategy` or `Base*Strategy` for shared parent classes

### Services: "Technical plumbing"

A service handles **low-level technical concerns** like calling external APIs. No business logic.

```ruby
# services/tabapay_client.rb
module FundingMethods
  module Services
    class TabapayClient
      def create_transaction(amount:, card_token:)
        # HTTP call to Tabapay API
        response = Faraday.post("#{base_url}/transactions", {
          amount: amount,
          token: card_token
        })

        # Return raw response - no business interpretation
        TabapayResponse.new(
          status: response.status,
          body: JSON.parse(response.body)
        )
      end
    end
  end
end
```

**Key traits:**
- Named as noun phrases: `TabapayClient`, `KafkaPublisher`
- No business logic
- Handles external communication
- Returns raw/minimal data structures

## Decision Tree: Use Case vs Strategy vs Service

```
Is it orchestrating multiple steps?
├─ YES → Use Case
└─ NO
   └─ Does it contain business logic?
      ├─ YES → Are there multiple ways to do it?
      │   ├─ YES → Strategy
      │   └─ NO → Still Strategy (single impl), or inline in Use Case
      └─ NO → Is it calling external systems?
          ├─ YES → Service
          └─ NO → Probably an Adapter or Repository
```

## Complete Example: Annotation Component

The `annotations` component is a minimal Clean Architecture implementation:

```
components/annotations/
├── app/
│   ├── public/
│   │   ├── annotations_api.rb           # Entry point
│   │   └── transaction_annotation_struct.rb  # DTO
│   ├── domain/
│   │   ├── use_cases/
│   │   │   ├── get_transaction_annotation.rb
│   │   │   └── save_transaction_annotation.rb
│   │   └── repositories/
│   │       └── active_record_transaction_annotation_repository.rb
│   ├── adapters/
│   │   └── active_record_transaction_annotation_adapter.rb
│   └── models/
│       └── transaction_annotation.rb    # ActiveRecord
└── spec/
    └── [mirrors app/ structure]
```

### Data Flow

```
External caller
    ↓
AnnotationsApi.get_transaction_annotations()     # public/
    ↓
ActiveRecordTransactionAnnotationRepository.batch_find()  # domain/repositories/
    ↓
TransactionAnnotation.where(...)                 # models/ (ActiveRecord)
    ↓
ActiveRecordTransactionAnnotationAdapter.call()  # adapters/
    ↓
TransactionAnnotationStruct                      # public/ (returned)
```

## Repositories vs Adapters

**Repository**: Handles data access (CRUD). Knows about persistence.

```ruby
# domain/repositories/active_record_deposit_repository.rb
def find!(deposit_id:)
  deposit = ::Deposit.find_by!(canonical_id: deposit_id)
  deposit_adapter.call(deposit: deposit)  # Returns domain struct
end
```

**Adapter**: Maps external data → domain data. No persistence logic.

```ruby
# adapters/active_record_deposit_adapter.rb
def call(deposit:)
  DepositStruct.new(
    id: deposit.canonical_id,
    amount: deposit.amount,
    status: deposit.status
    # ... only domain-relevant fields
  )
end
```

**Rule**: Repository uses Adapter. Adapter knows nothing about Repository.

## Public Structs (DTOs)

Data crossing component boundaries must be Structs, not ActiveRecord models:

```ruby
# public/transaction_annotation_struct.rb
module Annotations
  class TransactionAnnotationStruct < Common::Types::StrictStruct
    attribute :annotatable_canonical_id, Types::String
    attribute :annotatable_type, Types::String
    attribute :annotation, Types::String
    attribute :created_at, Types::Time
    attribute :updated_at, Types::Time
  end
end
```

**Why Structs?**
- Immutable, predictable
- No ActiveRecord magic leaking across boundaries
- Explicit contract between components
- Easy to test

## Dependency Injection with Dry::Initializer

All external dependencies are injected:

```ruby
module FundingIntents
  module UseCases
    class ProcessDeposit
      extend Dry::Initializer

      # Dependencies with defaults
      option :deposit_repository, default: proc { Repositories::ActiveRecordDepositRepository.new }
      option :event_bus, default: proc { Events::EventBus.instance }

      def call(deposit_id:)
        # Use injected dependencies
      end
    end
  end
end

# In production: uses defaults
ProcessDeposit.new.call(deposit_id: "123")

# In tests: inject mocks
ProcessDeposit.new(
  deposit_repository: mock_repository,
  event_bus: mock_event_bus
).call(deposit_id: "123")
```

## Common Pitfalls

### 1. Putting business logic in Services

**BAD** - Service interprets business meaning:
```ruby
class TabapayClient
  def create_transaction(...)
    response = api_call(...)
    if response.status == 504
      raise TemporaryOutage  # Business interpretation!
    end
  end
end
```

**GOOD** - Service returns raw data, Adapter/Validator interprets:
```ruby
class TabapayClient
  def create_transaction(...)
    response = api_call(...)
    TabapayResponse.new(status: response.status, body: response.body)
  end
end

class TabapayResponseValidator
  def validate(response:)
    return [Constants::TEMPORARY_OUTAGE] if response.status == 504
    []
  end
end
```

### 2. Use Case doing too much

**BAD** - Use case contains business logic:
```ruby
class ProcessDeposit
  def call(deposit_id:)
    deposit = repository.find!(deposit_id)

    # Business logic crammed into use case
    if deposit.amount > 10000 && deposit.account.type == 'rrsp'
      instructions = build_large_rrsp_instructions(deposit)
    elsif deposit.immediate?
      instructions = build_immediate_instructions(deposit)
    else
      instructions = build_standard_instructions(deposit)
    end

    post_instructions(instructions)
  end
end
```

**GOOD** - Delegate to Strategy:
```ruby
class ProcessDeposit
  def call(deposit_id:)
    deposit = repository.find!(deposit_id)
    strategy = strategy_factory.build(deposit: deposit)
    strategy.call(deposit: deposit)
  end
end
```

### 3. Exposing ActiveRecord across boundaries

**BAD** - Returning ActiveRecord model:
```ruby
class AnnotationsApi
  def get_annotation(id:)
    TransactionAnnotation.find(id)  # ActiveRecord leaks out!
  end
end
```

**GOOD** - Return Struct:
```ruby
class AnnotationsApi
  def get_annotation(id:)
    repository.find(id: id)  # Returns TransactionAnnotationStruct
  end
end
```

## When to Use Full Architecture

**Start simple.** Not every component needs all layers. Begin with `public/` + `models/`, then add layers as complexity emerges:

| Complexity | Use |
|------------|-----|
| Simple CRUD, no business logic | `public/` + `models/` only |
| Some business rules | Add `domain/use_cases/` |
| Multiple algorithms | Add `domain/strategies/` |
| External APIs | Add `services/` |
| Complex data mapping | Add `adapters/` |

Add layers when you need them, not preemptively.

**Nested bounded contexts**: Components with sub-domains (like `funding_methods/payment_rails/eft_bank_account/`) can mirror the top-level structure with their own `domain/use_cases/`, `domain/repositories/`, etc.

## Commands Reference

```bash
# Check component boundaries
bundle exec packwerk check

# Run component tests
bundle exec rspec components/annotations/

# Generate component from template
# See: https://github.com/wealthsimple/software-templates/tree/master/ruby/rails-component
```

## Further Reading

- ADR-0006: `docs/adr/0006-develop-fort-knox-as-a-modular-monolith.md`
- Component guide: `docs/development_guides/architecture_guides/components/README.md`
- [Modular Monolith: A Primer](http://www.kamilgrzybek.com/design/modular-monolith-primer/)
