# GRead Themes

This directory contains theme definitions for the GRead app. Themes are loaded automatically from JSON files in this directory.

## Theme File Format

Each theme must be a JSON file with the following structure:

```json
{
  "id": "unique-theme-id",
  "name": "Theme Name",
  "description": "A brief description of the theme",
  "primary_color": "#007AFF",
  "secondary_color": "#5AC8FA",
  "accent_color": "#34C759",
  "background_color": "#FFFFFF",
  "unlock_requirement": {
    "stat": "booksCompleted",
    "value": 5
  }
}
```

### Required Fields

- **id** (string): Unique identifier for the theme. Used internally and must match the filename (without .json extension). Can contain lowercase letters, numbers, and hyphens.
- **name** (string): Display name shown in the app
- **description** (string): Brief description of the theme's style/inspiration
- **primary_color** (hex string): Main color for UI elements (e.g., buttons, links)
- **secondary_color** (hex string): Secondary accent color
- **accent_color** (hex string): Accent color for highlights and important elements
- **background_color** (hex string): Background color for views

### Optional Fields

- **unlock_requirement** (object): Requirement to unlock this theme. If omitted, theme is always available. Contains:
  - **stat** (string): The stat to check. Valid values:
    - `"booksCompleted"` - Number of books user has finished
    - `"pagesRead"` - Total pages read
    - `"points"` - User's total points
    - `"booksAdded"` - Books user has added to the library
    - `"approvedReports"` - Reports the user has made that were approved
  - **value** (integer): The minimum value the stat must reach to unlock this theme

### Color Format

All colors must be specified as hexadecimal color codes with a `#` prefix:
- Valid: `#FF6B35`, `#0077BE`
- Invalid: `FF6B35`, `rgb(255, 107, 53)`

## Adding New Themes

### Method 1: Add to App Bundle (Built-in Themes)

1. Create a new JSON file in this `Themes/` directory
2. Name the file following the theme's id (e.g., `MyTheme.json` for id `my-theme`)
3. Add your theme JSON content
4. Build and run the app - themes are loaded automatically!

### Method 2: Add Custom Themes at Runtime

Users can also add custom themes by placing JSON files in their device's Documents directory:

```
~/Documents/GReadThemes/YourTheme.json
```

The app automatically scans both locations when it launches.

## Theme ID Naming Convention

Use the following format for theme IDs:
- Lowercase letters only
- Use hyphens to separate words
- Keep it short and descriptive

Examples:
- `ocean`
- `sunset`
- `dark-mode`
- `high-contrast`

## Example Themes

### Ocean Theme
A calm, ocean-inspired theme with cool blues and cyans. Unlocked after completing 5 books.

```json
{
  "id": "ocean",
  "name": "Ocean",
  "description": "Calm ocean-inspired colors",
  "primary_color": "#0077BE",
  "secondary_color": "#00A4EF",
  "accent_color": "#7DD3FC",
  "background_color": "#F0F9FF",
  "unlock_requirement": {
    "stat": "booksCompleted",
    "value": 5
  }
}
```

### Sunset Theme
A warm, energetic theme inspired by sunset colors. Unlocked after reading 500 pages.

```json
{
  "id": "sunset",
  "name": "Sunset",
  "description": "Warm sunset colors",
  "primary_color": "#FF6B35",
  "secondary_color": "#F7931E",
  "accent_color": "#FDB833",
  "background_color": "#FFF8F3",
  "unlock_requirement": {
    "stat": "pagesRead",
    "value": 500
  }
}
```

### Forest Theme
A natural, calming theme with forest greens. Unlocked after earning 100 points.

```json
{
  "id": "forest",
  "name": "Forest",
  "description": "Natural forest colors",
  "primary_color": "#2D6A4F",
  "secondary_color": "#40916C",
  "accent_color": "#52B788",
  "background_color": "#F1FAEE",
  "unlock_requirement": {
    "stat": "points",
    "value": 100
  }
}
```

### Lavender Theme
An elegant, sophisticated theme with purple tones. Unlocked after adding 10 books.

```json
{
  "id": "purple",
  "name": "Lavender",
  "description": "Elegant purple tones",
  "primary_color": "#7209B7",
  "secondary_color": "#B5179E",
  "accent_color": "#F72585",
  "background_color": "#F8F7FF",
  "unlock_requirement": {
    "stat": "booksAdded",
    "value": 10
  }
}
```

### Free Theme (Always Available)
A theme with no unlock requirement is always available to all users.

```json
{
  "id": "free-theme",
  "name": "My Free Theme",
  "description": "Always available theme",
  "primary_color": "#FF0000",
  "secondary_color": "#00FF00",
  "accent_color": "#0000FF",
  "background_color": "#FFFFFF"
}
```

## Tips for Creating Great Themes

1. **Color Harmony**: Ensure your colors work well together. Use color theory principles.
2. **Contrast**: Make sure text is readable on your background color (at least 4.5:1 contrast ratio)
3. **Accessibility**: Consider colorblind users when choosing primary/secondary colors
4. **Testing**: Test your theme in the app to ensure it looks good across all screens
5. **Consistency**: Keep your color palette to 4-5 colors for a cohesive look

## Reloading Themes

To reload themes after adding a new file at runtime, call:
```swift
ThemeManager.shared.reloadThemes()
```

This is useful if you're adding themes to the Documents directory programmatically.

## Theme Unlocking

Themes automatically unlock when users reach the stat requirements defined in each theme's `unlock_requirement` field. The system checks unlock conditions automatically when:

1. **App Launch**: On startup, all themes are checked against the user's current stats
2. **Stats Update**: Whenever user stats change, the system automatically checks for new unlocks
3. **Manual Check**: You can manually trigger unlock checks with:
   ```swift
   ThemeManager.shared.checkAndUnlockCosmetics(stats: userStats)
   ```

### How to Set Unlock Requirements

Simply add an `unlock_requirement` object to your theme JSON:

```json
"unlock_requirement": {
  "stat": "booksCompleted",
  "value": 5
}
```

If you omit the `unlock_requirement` field, the theme is always available to all users.

### Available Stat Types

- `"booksCompleted"` - Number of completed books
- `"pagesRead"` - Total pages read
- `"points"` - User's accumulated points
- `"booksAdded"` - Books user has added to library
- `"approvedReports"` - User's approved reports

Users are notified via push notification when they unlock new themes!
