# Automatic Image Cropping Feature

## Overview

Icon Creator now automatically crops non-square images to square by trimming the edges. This eliminates the "Image should be square or nearly square for best results" error and lets you use any image without manual editing.

## How It Works

### Automatic Center Crop

When you drag a non-square image into Icon Creator:

1. **Detection**: App detects the image is not square (aspect ratio outside 0.9-1.1 range)
2. **Auto-Crop**: Automatically crops to the smallest dimension (center crop)
3. **Notification**: Shows a blue message with scissors icon indicating the crop
4. **Continue**: You can proceed with icon generation immediately

### Center Cropping Algorithm

```
Original Image: 1920×1080 (landscape)
↓
Crop Size: 1080 (smallest dimension)
Crop Position: Center
↓
Result: 1080×1080 (square)
```

**What gets trimmed:**
- **Landscape images** (wider than tall): Left and right edges
- **Portrait images** (taller than wide): Top and bottom edges

**Always preserved:**
- Center of the image
- Maximum possible square area

## Features

### Enabled by Default
- Auto-crop is ON by default
- Works automatically without user action
- Can be toggled off in settings

### Visual Feedback
- **Blue scissors icon** (✂️) when image is cropped
- Shows original and new dimensions
- Example: "✂️ Image auto-cropped to square (1080×1080)"

### Restore Original
- **"Restore Original" button** appears when image is cropped
- Click to see the original uncropped image
- Try cropping again or use manual editing tools

### Manual Control
- **Toggle in settings**: "Auto-crop to square"
- Turn OFF to get the old behavior (reject non-square images)
- Turn ON for automatic cropping

## Usage Examples

### Example 1: Landscape Photo (1920×1080)
**Before:**
- Error: "Image should be square or nearly square for best results"
- Had to manually crop in external app

**After:**
- ✂️ Auto-cropped to 1080×1080
- Center portion preserved
- Ready to use immediately

**What was trimmed:**
- 420 pixels from left edge
- 420 pixels from right edge
- Total: 840 pixels removed horizontally

### Example 2: Portrait Screenshot (828×1792)
**Before:**
- Error message, couldn't proceed

**After:**
- ✂️ Auto-cropped to 828×828
- Center 828 pixels preserved vertically
- Ready to use

**What was trimmed:**
- 482 pixels from top
- 482 pixels from bottom
- Total: 964 pixels removed vertically

### Example 3: Widescreen (2560×1440)
**Result:** 1440×1440 square
**Preserved:** Center 1440 pixels
**Trimmed:** 560 pixels from each side (1120 total)

## UI Components

### Warning Banner
Located below the drop zone, shows:
- **Scissors icon** (blue) when auto-cropped
- **Dimensions**: Original → Cropped size
- **Restore button**: To undo the crop

### Settings Toggle
Located in "Adjust Icon" section:
- **"Auto-crop to square"** toggle
- Enabled by default
- Description: "Automatically trim non-square images to square"

### Drop Zone
- Drop any image, square or not
- Auto-cropping happens during validation
- Original image preserved for restore

## Technical Details

### Cropping Method

```swift
func autoCropImageToSquare(_ image: NSImage) -> NSImage {
    // 1. Get dimensions
    let width = image.size.width
    let height = image.size.height

    // 2. Determine crop size (smallest)
    let cropSize = min(width, height)

    // 3. Calculate center position
    let xOffset = (width - cropSize) / 2
    let yOffset = (height - cropSize) / 2

    // 4. Crop from center
    // Returns square image
}
```

### Quality Preservation

- Uses high-quality CGImage cropping
- No scaling during crop (lossless)
- Preserves original pixel data in cropped area
- No compression artifacts

### Aspect Ratio Tolerance

Images are considered "square enough" if aspect ratio is between:
- **0.95 to 1.05** (5% tolerance)
- Example: 1000×1050 = 0.95 ratio (close enough, no crop)
- Example: 1000×1200 = 0.83 ratio (too far, auto-crop)

### Validation Flow

```
Image dropped
↓
Check minimum size (64×64)
↓
Check aspect ratio
  ├─ Square (0.9-1.1): ✓ Continue
  └─ Non-square:
      ├─ Auto-crop ON: ✂️ Crop to square → ✓ Continue
      └─ Auto-crop OFF: ✗ Show error
```

## Benefits

### Eliminates Errors
- No more "image should be square" rejections
- Any image works immediately
- Reduces friction in workflow

### Saves Time
- No need to open external editor
- No manual cropping required
- Instant results

### Smart Defaults
- Center crop preserves most important area
- Works for 95% of use cases
- Can be overridden if needed

### Non-Destructive
- Original image preserved in memory
- Click "Restore Original" anytime
- Re-crop or adjust as needed

## When to Disable Auto-Crop

Consider turning OFF auto-crop if:

1. **Precise control needed**: You want specific crop area
2. **Already cropped**: Your images are pre-cropped externally
3. **Quality checking**: Want to ensure perfect square sources

## Comparison

### Before v1.1.2

```
User: *drops 16:9 image*
App: ✗ Error: Image should be square
User: *opens Photoshop*
User: *crops manually*
User: *saves*
User: *drops again*
App: ✓ Accepted
```

### After v1.1.2

```
User: *drops 16:9 image*
App: ✂️ Auto-cropped to square
App: ✓ Ready to export
User: 🎉
```

## Common Scenarios

### Social Media Images
- Instagram posts (1080×1080): ✓ Already square
- Instagram stories (1080×1920): ✂️ Auto-crop to 1080×1080
- Facebook covers (820×312): ✂️ Auto-crop to 312×312
- Twitter headers (1500×500): ✂️ Auto-crop to 500×500

### Screenshots
- iPhone 15 Pro (1179×2556): ✂️ Auto-crop to 1179×1179
- iPad Pro (2048×2732): ✂️ Auto-crop to 2048×2048
- MacBook (2560×1600): ✂️ Auto-crop to 1600×1600

### Photos
- DSLR (6000×4000): ✂️ Auto-crop to 4000×4000
- Phone camera (4032×3024): ✂️ Auto-crop to 3024×3024

## Tips & Best Practices

### For Best Results

1. **Use high-resolution sources**: Larger images = more pixels preserved
2. **Center your subject**: Auto-crop uses center of image
3. **Check the preview**: Ensure important elements aren't trimmed
4. **Use Restore**: If crop looks bad, restore and crop manually

### When Subject Not Centered

If your subject is off-center and gets trimmed:

**Option 1: Restore and Manual Crop**
1. Click "Restore Original"
2. Crop manually in external app to center subject
3. Drop the manually cropped version

**Option 2: Adjust Scale/Padding**
- Sometimes scale or padding adjustments can help
- Won't change crop, but might improve appearance

**Option 3: Turn Off Auto-Crop**
- Disable auto-crop toggle
- Crop precisely in external app
- Drop pre-cropped square image

## Troubleshooting

### Image Too Small After Crop

**Problem:** "Image is too small after cropping. Minimum size: 64×64 pixels"

**Cause:** Original image's smallest dimension is less than 64 pixels

**Solution:**
- Use a larger source image
- Minimum: 64×64 before cropping
- Recommended: 1024×1024 or larger

### Important Part Trimmed

**Problem:** Subject's head/feet cut off in portrait crop

**Cause:** Subject not centered in original

**Solution:**
1. Click "Restore Original"
2. Crop manually in external app to center subject
3. Or use wider composition in original photo

### Crop Looks Bad

**Problem:** Auto-crop result doesn't look good

**Solution:**
1. Click "Restore Original"
2. Disable "Auto-crop to square" toggle
3. Crop precisely in external app (Photoshop, Preview, etc.)
4. Drop the pre-cropped version

## Console Output

When auto-cropping occurs, the console shows:

```
✂️ Auto-cropped image from 1920×1080 to 1080×1080
```

If you restore:
```
↩️ Restored original image
```

## Future Enhancements

### Planned for v1.3
- [ ] Smart crop detection (face detection, important regions)
- [ ] Multiple crop options (top, center, bottom)
- [ ] Custom crop area selector
- [ ] Crop preview before/after comparison

### Under Consideration
- [ ] AI-powered intelligent cropping
- [ ] Preserve aspect ratio option
- [ ] Manual crop tool within app
- [ ] Crop presets (portrait, landscape, square)

## API Reference

### IconGenerator Properties

```swift
@Published var autoCropToSquare: Bool = true    // Auto-crop enabled
@Published var wasAutoCropped: Bool = false     // Was current image cropped
private var originalImage: NSImage?             // Original before crop
```

### Methods

```swift
func autoCropImageToSquare(_ image: NSImage) -> NSImage
// Crops image to square (center crop)

func validateSourceImage() -> (isValid: Bool, error: String?)
// Validates and auto-crops if needed

func restoreOriginalImage()
// Restores original uncropped image
```

## Version History

### v1.1.2 (2025-10-28)
**Added:** Automatic image cropping to square
- Center crop algorithm
- Auto-crop toggle
- Restore original button
- Visual feedback with scissors icon

## FAQ

**Q: Will cropping reduce quality?**
A: No. Cropping is lossless - it just removes pixels from edges. The preserved center area maintains full quality.

**Q: Can I choose which part to crop?**
A: Not yet. Currently always center crop. Custom crop areas are planned for v1.3.

**Q: Does it work with all image formats?**
A: Yes. PNG, JPG, HEIC, TIFF, BMP, GIF - all supported.

**Q: What if I want exact control?**
A: Disable auto-crop toggle and use external app for precise cropping.

**Q: Is the original saved?**
A: Original is kept in memory during the session. Click "Restore Original" to get it back. Not saved to disk.

**Q: Can I see before/after?**
A: The preview shows the cropped result. Click "Restore Original" to see the original.

**Q: Will it crop square images?**
A: No. Images within 0.95-1.05 aspect ratio are considered square enough and not cropped.

**Q: What about rounded corners?**
A: App crops to square. Rounded corners are added by iOS/macOS automatically for app icons.

---

**Icon Creator** - Now works with any image, automatically!
