---
name: motion-react
description: React animation with Motion library (formerly Framer Motion). Use when creating animations, transitions, gestures, scroll effects, or layout animations in React. Covers motion components, AnimatePresence, variants, and common patterns.
---

# Motion for React

Motion (formerly Framer Motion) is a production-ready animation library for React that provides declarative animations, gestures, and layout transitions.

## Quick Start

```bash
npm install motion
```

```tsx
import { motion } from "motion/react"

// Basic animation
<motion.div animate={{ opacity: 1, scale: 1.2 }} />
```

## Core Concepts

### Motion Components

Every HTML/SVG element has a motion equivalent:

```tsx
<motion.div />
<motion.button />
<motion.svg />
<motion.circle />
```

### The `animate` Prop

When values change, the component animates automatically:

```tsx
<motion.div animate={{ opacity: 1, x: 100 }} />
```

### The `initial` Prop

Define starting state for enter animations:

```tsx
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
/>
```

Disable enter animation with `initial={false}`:

```tsx
<motion.div initial={false} animate={{ scale: 1 }} />
```

## Transform Properties

Motion animates transform axes independently:

| Property | Description |
|----------|-------------|
| `x`, `y`, `z` | Translate |
| `scale`, `scaleX`, `scaleY` | Scale |
| `rotate`, `rotateX`, `rotateY`, `rotateZ` | Rotation |
| `skewX`, `skewY` | Skew |

```tsx
<motion.button
  initial={{ y: 10 }}
  animate={{ y: 0 }}
  whileHover={{ scale: 1.1 }}
  whileTap={{ scale: 0.9 }}
/>
```

## Transitions

Customize animation behavior:

```tsx
<motion.div
  animate={{ x: 100 }}
  transition={{
    type: "spring",
    stiffness: 100,
    damping: 10,
    duration: 0.5
  }}
/>
```

Spring physics for physical properties, easing for opacity/colors:

```tsx
<motion.div
  animate={{ x: 100, opacity: 1 }}
  transition={{
    x: { type: "spring", stiffness: 300 },
    opacity: { duration: 0.2 }
  }}
/>
```

## Gesture Animations

### Hover & Tap

```tsx
<motion.button
  whileHover={{ scale: 1.1, backgroundColor: "#f00" }}
  whileTap={{ scale: 0.95 }}
  whileFocus={{ outline: "2px solid blue" }}
/>
```

### Drag

```tsx
<motion.div
  drag           // both axes
  drag="x"       // horizontal only
  dragConstraints={{ left: 0, right: 300 }}
  dragElastic={0.2}
  whileDrag={{ scale: 1.1 }}
/>
```

Constrain to parent element:

```tsx
const constraintsRef = useRef(null)

<motion.div ref={constraintsRef}>
  <motion.div drag dragConstraints={constraintsRef} />
</motion.div>
```

## Exit Animations with AnimatePresence

**CRITICAL**: Wrap conditionally rendered elements in `AnimatePresence`:

```tsx
import { AnimatePresence, motion } from "motion/react"

<AnimatePresence>
  {isVisible && (
    <motion.div
      key="modal"  // Required unique key
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    />
  )}
</AnimatePresence>
```

### AnimatePresence Modes

```tsx
// Default - enter/exit simultaneously
<AnimatePresence mode="sync">

// Wait for exit before enter (slideshows)
<AnimatePresence mode="wait">

// Pop exiting elements out of layout flow
<AnimatePresence mode="popLayout">
```

### Slideshows with Changing Keys

```tsx
<AnimatePresence mode="wait">
  <motion.img
    key={image.src}  // Changing key triggers exit/enter
    src={image.src}
    initial={{ x: 300, opacity: 0 }}
    animate={{ x: 0, opacity: 1 }}
    exit={{ x: -300, opacity: 0 }}
  />
</AnimatePresence>
```

## Scroll Animations

### Scroll-Triggered (whileInView)

```tsx
<motion.div
  initial={{ opacity: 0, y: 50 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.5 }}
/>
```

### Scroll-Linked (useScroll)

```tsx
import { useScroll, motion } from "motion/react"

function ProgressBar() {
  const { scrollYProgress } = useScroll()
  return <motion.div style={{ scaleX: scrollYProgress }} />
}
```

## Layout Animations

Animate layout changes with a single prop:

```tsx
<motion.div layout />
```

### Shared Element Transitions

```tsx
// Selected item shows underline that animates between items
{items.map(item => (
  <li key={item.id}>
    {item.label}
    {item.isSelected && <motion.div layoutId="underline" />}
  </li>
))}
```

### Layout Options

```tsx
<motion.div layout />              // Animate size and position
<motion.div layout="position" />   // Position only
<motion.div layout="size" />       // Size only
```

### Fixing Layout Animation Issues

For scrollable containers:
```tsx
<motion.div layoutScroll style={{ overflow: "scroll" }}>
  <motion.div layout />
</motion.div>
```

For fixed positioning:
```tsx
<motion.div layoutRoot style={{ position: "fixed" }}>
  <motion.div layout />
</motion.div>
```

## Variants

Reusable animation states that propagate to children:

```tsx
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      when: "beforeChildren",
      staggerChildren: 0.1
    }
  }
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 }
}

<motion.ul
  variants={containerVariants}
  initial="hidden"
  animate="visible"
>
  <motion.li variants={itemVariants} />
  <motion.li variants={itemVariants} />
  <motion.li variants={itemVariants} />
</motion.ul>
```

### Dynamic Variants

```tsx
const variants = {
  visible: (i) => ({
    opacity: 1,
    transition: { delay: i * 0.1 }
  })
}

{items.map((item, i) => (
  <motion.div custom={i} variants={variants} animate="visible" />
))}
```

## Keyframes

Animate through multiple values:

```tsx
<motion.div animate={{ x: [0, 100, 50, 100] }} />

// Use null for current value
<motion.div animate={{ x: [null, 100, 0] }} />
```

Control timing:

```tsx
<motion.div
  animate={{
    x: [0, 100, 200],
    transition: {
      duration: 3,
      times: [0, 0.2, 1]  // Keyframe positions 0-1
    }
  }}
/>
```

## Motion Values

For performance-critical updates without re-renders:

```tsx
import { useMotionValue, useTransform, motion } from "motion/react"

function Component() {
  const x = useMotionValue(0)
  const opacity = useTransform(x, [-200, 0, 200], [0, 1, 0])

  return <motion.div drag="x" style={{ x, opacity }} />
}
```

## Common Patterns

### Fade In on Mount

```tsx
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{ duration: 0.3 }}
/>
```

### Staggered List

```tsx
<motion.ul
  initial="hidden"
  animate="visible"
  variants={{
    visible: { transition: { staggerChildren: 0.07 } }
  }}
>
  {items.map(item => (
    <motion.li
      key={item.id}
      variants={{
        hidden: { opacity: 0, x: -20 },
        visible: { opacity: 1, x: 0 }
      }}
    />
  ))}
</motion.ul>
```

### Modal with Backdrop

```tsx
<AnimatePresence>
  {isOpen && (
    <>
      <motion.div
        key="backdrop"
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.5 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        style={{ position: "fixed", inset: 0, background: "#000" }}
      />
      <motion.div
        key="modal"
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        style={{ position: "fixed", ... }}
      >
        {children}
      </motion.div>
    </>
  )}
</AnimatePresence>
```

### Animate Height Auto

```tsx
<motion.div
  initial={{ height: 0 }}
  animate={{ height: "auto" }}
  transition={{ duration: 0.3 }}
/>
```

## Common Pitfalls

1. **Missing key on AnimatePresence children** - Each direct child needs a unique, stable `key`

   **BAD**:
   ```tsx
   {items.map((item, index) => <motion.div key={index} />)}
   ```

   **GOOD**:
   ```tsx
   {items.map(item => <motion.div key={item.id} />)}
   ```

2. **AnimatePresence outside conditional** - It must wrap the conditional, not be inside it

   **BAD**:
   ```tsx
   {isVisible && <AnimatePresence><Component /></AnimatePresence>}
   ```

   **GOOD**:
   ```tsx
   <AnimatePresence>{isVisible && <Component />}</AnimatePresence>
   ```

3. **Using display: inline** - Browsers don't apply transforms to inline elements

4. **Border radius distortion in layout animations** - Set via style prop:
   ```tsx
   <motion.div layout style={{ borderRadius: 20 }} />
   ```

5. **Forgetting forwardRef for custom components**:
   ```tsx
   const MotionComponent = motion.create(
     React.forwardRef((props, ref) => <div ref={ref} {...props} />)
   )
   ```

6. **Creating motion.create() inside render** - Creates new component each render:

   **BAD**:
   ```tsx
   function Parent() {
     const MotionChild = motion.create(Child)  // New component every render!
     return <MotionChild />
   }
   ```

   **GOOD**:
   ```tsx
   const MotionChild = motion.create(Child)  // Outside component
   function Parent() {
     return <MotionChild />
   }
   ```

## Server Components (Next.js)

Use the client import for RSC:

```tsx
import * as motion from "motion/react-client"
```

## Quick Reference

| Prop | Purpose |
|------|---------|
| `initial` | Starting state |
| `animate` | Target state |
| `exit` | Exit animation (requires AnimatePresence) |
| `transition` | Animation options |
| `variants` | Named animation states |
| `whileHover` | Hover state |
| `whileTap` | Press state |
| `whileDrag` | Drag state |
| `whileFocus` | Focus state |
| `whileInView` | In viewport state |
| `layout` | Enable layout animations |
| `layoutId` | Shared element transitions |
| `drag` | Enable dragging |