# RelayDrivers Flutter App - Claude Code Guidelines

## WCAG Contrast Requirements (MANDATORY)

**All foreground/background color combinations MUST meet WCAG 2.1 AA minimum contrast ratio of 4.5:1.**

### Before Using ANY Color Combination

1. **Check contrast ratio** using a tool like webaim.org/resources/contrastchecker
2. If ratio < 4.5:1, **do not use that combination**
3. When in doubt, use high-contrast pairs (dark text on light backgrounds, or white text on dark backgrounds)

### Known Problem Combinations (BANNED)

| Foreground | Background | Issue |
|------------|------------|-------|
| Green (`#10B981`) | Pink gradient | Fails contrast on light pink |
| Red (`#EF4444`) | Pink gradient | Fails contrast on light pink |
| Warning yellow | Light backgrounds | Often fails |
| Success green | Colored backgrounds | Often fails |

### Safe Combinations

| Context | Foreground | Background | Ratio |
|---------|------------|------------|-------|
| UK Licence Card | `#2D1F3D` (dark purple) | Pink gradient | 7:1+ |
| UK Licence Card buttons | `#2D1F3D` | White with alpha | 7:1+ |
| Status badges on cards | Dark text on white background | Pink card | 7:1+ |

### Rule Enforcement

When adding colors to any widget:
1. Consider the background it will appear on
2. Avoid semantic colors (success/warning/danger) on colored backgrounds
3. Prefer neutral dark/light pairs for complex backgrounds
4. Test in both light and dark themes

---

## Code Style

- **NO emojis** in code (documentation files may use them)
- Follow existing patterns in the codebase
- Use Riverpod for state management
- Use go_router for navigation

## Testing

Run tests before committing:
```bash
flutter test
flutter analyze
```

## Deployment

CI/CD auto-deploys to Firebase Hosting on push to main branch.
