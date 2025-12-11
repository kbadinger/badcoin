# BlockBook UI Color Fix Guide

## Problem Summary
1. **BADCOIN logo/text** is not visible enough (wrong color/contrast)
2. **Address links** in Rich List are too dark and hard to read
3. Need better color contrast throughout the UI

## What is a "Rich List"?
A Rich List shows the **top 50 addresses ranked by their coin balance** - basically showing who holds the most Badcoin on the blockchain.

---

## Solution Approaches

### Approach 1: Quick CSS Override (Nginx injection)
**Pros:** Fast, no rebuild needed
**Cons:** May not work perfectly with all BlockBook pages

```bash
./deploy-custom-css.sh
```

This script will:
- Upload `blockbook-custom.css` to your server
- Configure nginx to inject the CSS into all pages
- Reload nginx

### Approach 2: Proper Source Modification (Recommended)
**Pros:** Permanent, proper fix
**Cons:** Requires rebuild (~15 min) and redeployment

```bash
./fix-blockbook-colors.sh
```

This script will:
1. Clone/update BlockBook repository locally
2. Create custom CSS file in BlockBook source
3. Modify HTML templates to include the custom CSS
4. Build a new BlockBook binary with embedded custom styles
5. Provide instructions for deployment

After building, deploy to your server:
```bash
# Copy new binary
scp ~/blockbook/blockbook-badcoin root@badcoin.kbadinger.com:/opt/blockbook/badcoin/

# Restart service
ssh root@badcoin.kbadinger.com 'systemctl restart blockbook-badcoin'
```

---

## Color Changes Applied

### 1. BADCOIN Logo/Text
- Changed to **bright red (#e74c3c)**
- Added bold weight for visibility
- Added text shadow for better contrast

### 2. Address Links
- Changed to **bright blue (#3498db)**
- Darker blue (#2980b9) on hover
- Added underline on hover for clarity

### 3. Table Improvements
- Increased text contrast (#ecf0f1)
- Better table header backgrounds
- Hover effects for rows

### 4. Overall Theme
- Improved card backgrounds
- Better contrast ratios throughout

---

## Testing Your Changes

After deploying, test these pages:
1. **Homepage** - Check BADCOIN logo visibility
2. **Rich List** (`/richlist`) - Verify address links are readable
3. **Address page** - Click an address link to test
4. **Block page** - Check all text is visible

---

## Troubleshooting

### Nginx CSS injection not working?
If Approach 1 doesn't work:
1. Check nginx has `sub_filter` module: `nginx -V 2>&1 | grep sub`
2. Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)
3. Check `/custom.css` is accessible: `curl https://badcoin.kbadinger.com/custom.css`

### BlockBook build fails?
Ensure you have:
- Go 1.21.5+ installed
- All dependencies: `apt-get install build-essential git pkg-config libzmq3-dev librocksdb-dev`

### Colors still not right?
You can customize the colors in:
- **Quick method:** Edit `blockbook-custom.css` locally, re-run `deploy-custom-css.sh`
- **Proper method:** Edit `~/blockbook/static/css/custom-badcoin.css`, rebuild and redeploy

---

## Recommended Approach

For **permanent fix**: Use Approach 2 (source modification)

**Steps:**
```bash
# 1. Build locally with custom colors
./fix-blockbook-colors.sh

# 2. Deploy to server
scp ~/blockbook/blockbook-badcoin root@badcoin.kbadinger.com:/opt/blockbook/badcoin/

# 3. Restart service on server
ssh root@badcoin.kbadinger.com 'systemctl restart blockbook-badcoin'

# 4. Test
# Open https://badcoin.kbadinger.com in browser (may need to clear cache)
```
