---
name: french-translations
description: Add French translations to front-end-monorepo locale files. Use when adding or updating translations in locale-fr_CA.json/locale-en_CA.json. Covers Quebec French conventions, quote replacement, and key parity verification.
---

# French Translation Process (front-end-monorepo)

## Pre-flight: Locate Files

Before starting, find these files in the package:
- `*untranslated*.json` (if exists)
- `locale-fr_CA.json`
- `locale-en_CA.json`
- `locale/index.ts`

```bash
# Find locale files in a package
find libs/path/to/package -name "locale*.json" -o -name "*untranslated*.json"
```

## Translation Steps Checklist

**DO NOT SKIP ANY STEP**

### 1. Add translations to BOTH files

Add identical keys to `locale-fr_CA.json` AND `locale-en_CA.json`:

```json
// locale-en_CA.json
{
  "myNewKey": "English text here"
}

// locale-fr_CA.json
{
  "myNewKey": "French text here"
}
```

### 2. Use Quebec French (francais quebecois)

**Tone**: Formal, transparent, supportive

**Common patterns**:
- "vous" (formal you), not "tu"
- Currency: `{{amount}} $` (dollar sign after, with space)
- Numbers: spaces as thousand separators (1 000 $)

### 3. Update locale/index.ts

Remove untranslated file imports:

```typescript
// BEFORE
import untranslated from './untranslated.json';
import frCA from './locale-fr_CA.json';
import enCA from './locale-en_CA.json';

export const locales = { ...untranslated, ...frCA, ...enCA };

// AFTER
import frCA from './locale-fr_CA.json';
import enCA from './locale-en_CA.json';

export const locales = { ...frCA, ...enCA };
```

### 4. Delete untranslated file

If `*untranslated*.json` exists in the same folder, delete it after migrating keys.

### 5. Run quote replacement script

**REQUIRED** - Converts straight quotes to French typographic quotes:

```bash
./scripts/french-translations/replace_quotes.sh
```

### 6. Verify key parity

Ensure both files have identical keys:

```bash
diff <(jq -S 'keys' locale-fr_CA.json) <(jq -S 'keys' locale-en_CA.json)
```

No output = keys match. Any output = missing keys to fix.

## Quick Reference: French Typography

| English | French |
|---------|--------|
| "quoted" | << quoted >> (guillemets) |
| It's | C'est (apostrophe same) |
| $100 | 100 $ |
| 1,000 | 1 000 |

## Common Mistakes

1. **Adding to only one file** - Both locale files need the key
2. **Forgetting quote script** - Straight quotes fail lint
3. **Leaving untranslated imports** - Causes duplicate key warnings
4. **Using informal "tu"** - Wealthsimple uses formal "vous"

## Commands

```bash
# Run quote replacement
./scripts/french-translations/replace_quotes.sh

# Verify key parity
diff <(jq -S 'keys' locale-fr_CA.json) <(jq -S 'keys' locale-en_CA.json)

# Lint the package
pnpm nx run <project-name>:lint
```
