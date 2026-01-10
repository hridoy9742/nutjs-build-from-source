# Required File Changes

This document lists all the file modifications needed to build nut.js from source. These changes configure nut.js to use your local libnut-core build and handle premium package dependencies.

## File 1: `nut.js/providers/libnut/package.json`

### Change 1: Update platform-specific dependency

**Find:**
```json
"dependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-linux": "2.7.1",
  "@nut-tree/libnut-win32": "2.7.1"
}
```

**Replace with (Linux):**
```json
"dependencies": {
  "@nut-tree/libnut-linux": "file:../../../libnut-core"
},
"optionalDependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-win32": "2.7.1"
}
```

**Replace with (macOS):**
```json
"dependencies": {
  "@nut-tree/libnut-darwin": "file:../../../libnut-core"
},
"optionalDependencies": {
  "@nut-tree/libnut-linux": "2.7.1",
  "@nut-tree/libnut-win32": "2.7.1"
}
```

**Replace with (Windows):**
```json
"dependencies": {
  "@nut-tree/libnut-win32": "file:../../../libnut-core"
},
"optionalDependencies": {
  "@nut-tree/libnut-darwin": "2.7.1",
  "@nut-tree/libnut-linux": "2.7.1"
}
```

### Change 2: Update peer dependency version

**Find:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^3"
}
```

**Replace with:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^4"
}
```

## File 2: `nut.js/providers/clipboardy/package.json`

### Change: Update peer dependency version

**Find:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^3"
}
```

**Replace with:**
```json
"peerDependencies": {
  "@nut-tree/nut-js": "^4"
}
```

## File 3: `nut.js/examples/screen-test/package.json`

### Change: Make premium package optional

**Find:**
```json
"dependencies": {
  "@nut-tree/nut-js": "workspace:*",
  "@nut-tree/nl-matcher": "2.2.0"
}
```

**Replace with:**
```json
"dependencies": {
  "@nut-tree/nut-js": "workspace:*"
},
"optionalDependencies": {
  "@nut-tree/nl-matcher": "2.2.0"
}
```

## Summary

These three files need to be modified:

1. **`nut.js/providers/libnut/package.json`**
   - Change platform-specific dependency to `file:../../../libnut-core`
   - Move other platforms to `optionalDependencies`
   - Update peer dependency from `^3` to `^4`

2. **`nut.js/providers/clipboardy/package.json`**
   - Update peer dependency from `^3` to `^4`

3. **`nut.js/examples/screen-test/package.json`**
   - Move `@nut-tree/nl-matcher` to `optionalDependencies`

## Why These Changes?

- **File path dependency**: Points nut.js to your local libnut-core build instead of trying to fetch from npm
- **Optional dependencies**: Premium packages aren't available on public npm, so making them optional prevents installation failures
- **Peer dependency version**: Matches the workspace version (4.2.0) instead of the old version (3.x) that's not available

## Verification

After making these changes, verify the file paths are correct:

- From `nut.js/providers/libnut/` going up `../../../` should reach the directory containing both `nut.js/` and `libnut-core/`
- The structure should be:
  ```
  your-build-directory/
  ├── libnut-core/
  └── nut.js/
      └── providers/
          └── libnut/
              └── package.json  (this file)
  ```
